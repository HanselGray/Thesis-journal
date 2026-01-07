import sys

if len(sys.argv) < 2:
    print("Usage: python script.py <rule_count>")
    sys.exit(1)

rules = int(sys.argv[1])

code = r"""
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>
#include <linux/if_ether.h>
#include <linux/ip.h>

/* Per-CPU packet drop counter */
struct {
    __uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, __u64);
} drop_cnt SEC(".maps");

SEC("xdp")
int xdp_redirect_ip(struct xdp_md *ctx) {
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;

    struct ethhdr *eth = data;
    if ((void *)(eth + 1) > data_end)
        return XDP_PASS;

    if (eth->h_proto != __constant_htons(ETH_P_IP))
        return XDP_PASS;

    struct iphdr *iph = data + sizeof(struct ethhdr);
    if ((void *)(iph + 1) > data_end)
        return XDP_PASS;

    __u32 key = 0;
    __u64 *cnt;
"""

redirect = r"""
    /* If source is 10.10.1.2 -> redirect to ifindex 3 (ens37) */
    if (iph->saddr == bpf_htonl(0x0a0a0102)) {
        const unsigned char new_dst[ETH_ALEN] = {0x00, 0x0c, 0x29, 0x2a, 0x2e, 0xb4};
        const unsigned char new_src[ETH_ALEN] = {0x00, 0x0c, 0x29, 0x67, 0xe7, 0x63};

        __builtin_memcpy(eth->h_dest, new_dst, ETH_ALEN);
        __builtin_memcpy(eth->h_source, new_src, ETH_ALEN);

        /* Optional: count redirected packets as well */
        cnt = bpf_map_lookup_elem(&drop_cnt, &key);
        if (cnt)
            (*cnt)++;

        return bpf_redirect(3, 0);
    }
"""

with open("xdp_script/xdp_rules.c", "w") as f:
    f.write(code)

    # Generate scalable DROP rules
    for i in range(rules):
        g1 = i % 256
        g2 = i // 256
        f.write(f"""
    if (iph->saddr == bpf_htonl(0x0ad2{g2:02x}{g1:02x})) {{
        cnt = bpf_map_lookup_elem(&drop_cnt, &key);
        if (cnt)
            (*cnt)++;
        return XDP_DROP;
    }}
""")

    f.write(redirect)

    f.write("""
    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
""")
