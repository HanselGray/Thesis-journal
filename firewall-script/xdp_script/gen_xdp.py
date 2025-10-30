rules = 2000
code ="""#include<bpf/bpf_endian.h>
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <linux/if_ether.h>
#include <linux/ip.h>

SEC("xdp")
int xdp_drop_ip(struct xdp_md *ctx) {
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;

    struct ethhdr *eth = data;
    if ((void*)(eth + 1) > data_end) return XDP_PASS;

    if (eth->h_proto != __constant_htons(ETH_P_IP))
        return XDP_PASS;

    struct iphdr *iph = data + sizeof(struct ethhdr);
    if ((void*)(iph + 1) > data_end) return XDP_PASS;

"""

with open("xdp_rules.c", "w") as f:
    f.write(code)
    for i in range(rules):
        f.write(f'  if (iph->saddr == bpf_htonl(0x0a0000{i:02x})) return XDP_DROP;\n')
    f.write(f'\n    //Block attacker machine \n  if (iph->saddr == bpf_htonl(0x0a0a0102) ) return XDP_DROP; \n ')
    f.write(' return XDP_PASS;\n}\n')
    f.write('char _license[] SEC("license") = "GPL";\n')

