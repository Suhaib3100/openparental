package app.monii.managed.vpn

import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress

/**
 * DNS-only content filter. Only DNS (to a sentinel) is routed into the tunnel —
 * everything else goes straight out, so this can never break the device's
 * connectivity. Allowed queries are forwarded to Cloudflare-for-Families (which
 * blocks malware + adult upstream); the family's own blocked domains are
 * sinkholed locally. Every packet is handled fail-open.
 *
 * Honest limits (per the eng review): apps using their own DoH/DoT bypass this,
 * and a teen's own VPN evicts it. Production hardening belongs on a maintained
 * DNS-filter base; this is the bounded v1.
 */
class VpnFilterService : VpnService() {

    private var tun: ParcelFileDescriptor? = null

    @Volatile
    private var running = false
    private var worker: Thread? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stop()
            return START_NOT_STICKY
        }
        start()
        return START_STICKY
    }

    private fun start() {
        if (running) return
        val builder = Builder()
            .setSession("OpenParental filter")
            .addAddress(VPN_ADDR, 32)
            .addDnsServer(DNS_SENTINEL)
            .addRoute(DNS_SENTINEL, 32)
        runCatching { builder.addDisallowedApplication(packageName) }
        val pfd = runCatching { builder.establish() }.getOrNull() ?: return
        tun = pfd
        running = true
        Companion.active = true
        worker = Thread { loop(pfd) }.also {
            it.isDaemon = true
            it.start()
        }
    }

    private fun loop(pfd: ParcelFileDescriptor) {
        val input = FileInputStream(pfd.fileDescriptor)
        val output = FileOutputStream(pfd.fileDescriptor)
        val blocklist = DomainBlocklist(applicationContext)
        val upstream = DatagramSocket()
        protect(upstream)
        upstream.soTimeout = 5000
        val buf = ByteArray(MAX)
        try {
            while (running) {
                val n = input.read(buf)
                if (n <= 0) continue
                runCatching { handle(buf, n, output, upstream, blocklist) } // fail-open
            }
        } catch (_: Exception) {
            // tun closed / interrupted
        } finally {
            runCatching { upstream.close() }
            runCatching { input.close() }
            runCatching { output.close() }
        }
    }

    private fun handle(
        buf: ByteArray,
        n: Int,
        output: FileOutputStream,
        upstream: DatagramSocket,
        blocklist: DomainBlocklist,
    ) {
        if (n < 28) return
        if ((buf[0].toInt() and 0xF0) != 0x40) return // IPv4 only
        val ihl = (buf[0].toInt() and 0x0F) * 4
        if ((buf[9].toInt() and 0xFF) != 17) return // UDP only
        if (n < ihl + 8) return

        val srcIp = buf.copyOfRange(12, 16)
        val dstIp = buf.copyOfRange(16, 20)
        val srcPort = ((buf[ihl].toInt() and 0xFF) shl 8) or (buf[ihl + 1].toInt() and 0xFF)
        val dstPort = ((buf[ihl + 2].toInt() and 0xFF) shl 8) or (buf[ihl + 3].toInt() and 0xFF)
        if (dstPort != 53) return

        val dns = buf.copyOfRange(ihl + 8, n)
        val domain = DnsFilter.domainOf(dns)

        if (domain != null && blocklist.isBlocked(domain)) {
            val resp = DnsFilter.nxdomain(dns)
            output.write(IpUtil.buildUdp(dstIp, srcIp, dstPort, srcPort, resp))
            return
        }

        // forward to the family-safe upstream resolver, relay the reply back
        upstream.send(DatagramPacket(dns, dns.size, InetAddress.getByName(UPSTREAM), 53))
        val reply = ByteArray(MAX)
        val replyPkt = DatagramPacket(reply, reply.size)
        upstream.receive(replyPkt)
        val replyDns = reply.copyOfRange(0, replyPkt.length)
        output.write(IpUtil.buildUdp(dstIp, srcIp, dstPort, srcPort, replyDns))
    }

    private fun stop() {
        running = false
        Companion.active = false
        runCatching { tun?.close() }
        tun = null
        stopSelf()
    }

    override fun onDestroy() {
        stop()
        super.onDestroy()
    }

    companion object {
        const val ACTION_STOP = "app.monii.managed.vpn.STOP"
        private const val VPN_ADDR = "10.111.222.1"
        private const val DNS_SENTINEL = "10.111.222.2"
        private const val UPSTREAM = "1.1.1.3" // Cloudflare for Families
        private const val MAX = 32767

        @Volatile
        var active: Boolean = false
            private set

        fun isRunning(context: Context): Boolean = active
    }
}
