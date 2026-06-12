package app.monii.managed.vpn

/** Minimal IPv4 + UDP packet helpers for the DNS-only filter. */
object IpUtil {

    /** 16-bit one's-complement checksum (used for the IPv4 header). */
    fun checksum(data: ByteArray, offset: Int, length: Int): Int {
        var sum = 0L
        var i = offset
        var remaining = length
        while (remaining > 1) {
            val word = ((data[i].toInt() and 0xFF) shl 8) or (data[i + 1].toInt() and 0xFF)
            sum += word.toLong()
            i += 2
            remaining -= 2
        }
        if (remaining == 1) sum += ((data[i].toInt() and 0xFF) shl 8).toLong()
        while (sum shr 16 != 0L) sum = (sum and 0xFFFF) + (sum shr 16)
        return (sum.inv() and 0xFFFF).toInt()
    }

    /**
     * Build an IPv4 + UDP datagram. The UDP checksum is left 0 (explicitly allowed
     * for IPv4), so only the IP header checksum is computed — fewer ways to be wrong.
     */
    fun buildUdp(
        srcIp: ByteArray,
        dstIp: ByteArray,
        srcPort: Int,
        dstPort: Int,
        payload: ByteArray,
    ): ByteArray {
        val udpLen = 8 + payload.size
        val totalLen = 20 + udpLen
        val pkt = ByteArray(totalLen)

        // ---- IPv4 header (20 bytes) ----
        pkt[0] = 0x45 // version 4, IHL 5
        pkt[2] = ((totalLen shr 8) and 0xFF).toByte()
        pkt[3] = (totalLen and 0xFF).toByte()
        pkt[8] = 64 // TTL
        pkt[9] = 17 // protocol = UDP
        System.arraycopy(srcIp, 0, pkt, 12, 4)
        System.arraycopy(dstIp, 0, pkt, 16, 4)
        val ipChecksum = checksum(pkt, 0, 20)
        pkt[10] = ((ipChecksum shr 8) and 0xFF).toByte()
        pkt[11] = (ipChecksum and 0xFF).toByte()

        // ---- UDP header (8 bytes) ----
        val u = 20
        pkt[u] = ((srcPort shr 8) and 0xFF).toByte()
        pkt[u + 1] = (srcPort and 0xFF).toByte()
        pkt[u + 2] = ((dstPort shr 8) and 0xFF).toByte()
        pkt[u + 3] = (dstPort and 0xFF).toByte()
        pkt[u + 4] = ((udpLen shr 8) and 0xFF).toByte()
        pkt[u + 5] = (udpLen and 0xFF).toByte()
        // checksum (u+6, u+7) stays 0

        System.arraycopy(payload, 0, pkt, u + 8, payload.size)
        return pkt
    }
}
