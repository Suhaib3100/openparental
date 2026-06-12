package app.monii.managed.vpn

/** Tiny DNS message reader/writer — just enough to read the question and sinkhole. */
object DnsFilter {

    /** The queried domain from a DNS query message, or null if unparseable. */
    fun domainOf(dns: ByteArray): String? {
        if (dns.size < 13) return null
        var pos = 12 // 12-byte header, then QNAME
        val sb = StringBuilder()
        while (pos < dns.size) {
            val len = dns[pos].toInt() and 0xFF
            if (len == 0) break
            if (len and 0xC0 != 0) return null // compression pointer in a query — bail
            pos++
            if (pos + len > dns.size) return null
            if (sb.isNotEmpty()) sb.append('.')
            for (k in 0 until len) sb.append((dns[pos + k].toInt() and 0xFF).toChar())
            pos += len
        }
        val domain = sb.toString().lowercase()
        return domain.ifEmpty { null }
    }

    /** Turn a query into an NXDOMAIN response (blocks resolution cleanly). */
    fun nxdomain(query: ByteArray): ByteArray {
        val r = query.copyOf()
        // byte 2: QR=1, opcode=0, AA=0, TC=0, RD=(preserve)
        r[2] = (0x80 or (query[2].toInt() and 0x01)).toByte()
        // byte 3: RA=1, Z=0, RCODE=3 (NXDOMAIN)
        r[3] = 0x83.toByte()
        // zero ANCOUNT / NSCOUNT / ARCOUNT (keep QDCOUNT)
        for (i in 6..11) r[i] = 0
        return r
    }
}
