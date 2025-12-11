import sys

# Check if an argument was provided
if len(sys.argv) < 2:
    print("Usage: python script.py <first_argument>")
    sys.exit(1)

# Get the first argument (after the script name)
rules = int(sys.argv[1])
code ="""#include<bpf/bpf_endian.h>
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/if_ether.h>
#include <linux/ip.h>

SEC("xdp")
int xdp_redirect_ip(struct xdp_md *ctx) {
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;

    struct ethhdr *eth = data;
    if ((void*)(eth + 1) > data_end) return XDP_PASS;

    if (eth->h_proto != __constant_htons(ETH_P_IP))
        return XDP_PASS;

    struct iphdr *iph = data + sizeof(struct ethhdr);
    if ((void*)(iph + 1) > data_end) return XDP_PASS;

"""
redirect="""/* If source is 10.10.1.2 -> redirect to ifindex 3 (ens37).
       Rewrite L2 before redirecting: set dst MAC = receiver, src MAC = ens37 */
    if (iph->saddr == bpf_htonl(0x0a0a0102)) {
        /* receiver MAC (destination on the 10.10.2.x net) you provided */
        const unsigned char new_dst[ETH_ALEN] = {0x00, 0x0c, 0x29, 0x2a, 0x2e, 0xb4};
        /* ens37 MAC (source for outgoing frame) you provided */
        const unsigned char new_src[ETH_ALEN] = {0x00, 0x0c, 0x29, 0x67, 0xe7, 0x63};

        /* safe memcpy inside eBPF program */
        __builtin_memcpy(eth->h_dest, new_dst, ETH_ALEN);
        __builtin_memcpy(eth->h_source, new_src, ETH_ALEN);

        /* redirect to ifindex 3 */
        return bpf_redirect(3, 0);
    }
"""
with open("xdp_script/xdp_rules.c", "w") as f:
    f.write(code)
    for i in range(rules):
        g1 = i%256 
        g2 = i//256
        f.write(f'  if (iph->saddr == bpf_htonl(0x0ad2{g2:02x}{g1:02x})) return XDP_DROP;\n')
    f.write(redirect)
    f.write(' return XDP_PASS;\n}\n')
    f.write('char _license[] SEC("license") = "GPL";\n')

