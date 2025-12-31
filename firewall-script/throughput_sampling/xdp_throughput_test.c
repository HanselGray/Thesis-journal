#include<linux/bpf.h>
#include<bpf/bpf_helpers.h>


struct {
	__uint(type, BPF_MAP_TYPE_DEVMAP);
	__type(key, __u32);
	__type(value, __u32);
	__uint(max_entries, 10);
} dev_redirect SEC(".maps");


SEC("xdp")
int xdp_inspect_and_redirect(struct *xdp_md ctx)
{
	
}

char[] LICENSE = "GPL";
