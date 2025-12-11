import pandas as pd
import matplotlib.pyplot as plt
import os

# --- Step 1: Read the aggregated CSV file ---
file_path = "aggregate_128b.csv"  # change this to your actual file
df = pd.read_csv(file_path)

# --- Step 2: Ensure correct data types ---
df["rule_count"] = pd.to_numeric(df["rule_count"], errors="coerce")
df["packet_size"] = df["packet_size"].astype(str)

# --- Step 3: Make sure output directory exists ---
output_dir = "charts"
os.makedirs(output_dir, exist_ok=True)

# --- Step 4: Loop through each packet size and generate 3 charts ---
for pkt_size, subset in df.groupby("packet_size"):
    # --- Chart 1: avg_idle_pct ---
    plt.figure(figsize=(9, 6))
    for fw_name, group in subset.groupby("firewall_name"):
        plt.plot(group["rule_count"], group["avg_idle_pct"], marker='o', label=fw_name)
    plt.title(f"Average Idle % vs Rule Count ({pkt_size} packets)")
    plt.xlabel("Rule Count")
    plt.ylabel("Idle CPU (%)")
    plt.legend(title="Firewall")
    plt.grid(True)
    plt.tight_layout()
    out_path = os.path.join(output_dir, f"idle_{pkt_size}.png")
    plt.savefig(out_path)
    plt.close()
    print(f"✅ Saved: {out_path}")

    # --- Chart 2: avg_irq_per_s ---
    plt.figure(figsize=(9, 6))
    for fw_name, group in subset.groupby("firewall_name"):
        plt.plot(group["rule_count"], group["avg_irq_per_s"], marker='o', label=fw_name)
    plt.title(f"Average IRQ/s vs Rule Count ({pkt_size} packets)")
    plt.xlabel("Rule Count")
    plt.ylabel("IRQ per second")
    plt.legend(title="Firewall")
    plt.grid(True)
    plt.tight_layout()
    out_path = os.path.join(output_dir, f"irq_{pkt_size}.png")
    plt.savefig(out_path)
    plt.close()
    print(f"✅ Saved: {out_path}")

    # --- Chart 3: avg_softirq_per_s ---
    plt.figure(figsize=(9, 6))
    for fw_name, group in subset.groupby("firewall_name"):
        plt.plot(group["rule_count"], group["avg_softirq_per_s"], marker='o', label=fw_name)
    plt.title(f"Average SoftIRQ/s vs Rule Count ({pkt_size} packets)")
    plt.xlabel("Rule Count")
    plt.ylabel("SoftIRQ per second")
    plt.legend(title="Firewall")
    plt.grid(True)
    plt.tight_layout()
    out_path = os.path.join(output_dir, f"softirq_{pkt_size}.png")
    plt.savefig(out_path)
    plt.close()
    print(f"✅ Saved: {out_path}")
