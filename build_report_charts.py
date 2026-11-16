"""Create the four figures used by the LaTeX business report."""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "output" / "level_analysis_master.csv"
ASSETS = ROOT / "output" / "pdf" / "report_assets"

INK = "#385777"
BLUE = "#8FB7DC"
MAUVE = "#B095BB"
LAVENDER = "#C8C6E8"
GRAY = "#A8B8C9"


def save(fig, name):
    fig.savefig(ASSETS / name, dpi=220, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def plot_progression(df):
    fig, ax = plt.subplots(figsize=(10.8, 4.2))
    ax.plot(df["level_index"], df["reach_vs_level1"] * 100, color=INK, linewidth=2)
    ax.fill_between(
        df["level_index"], df["reach_vs_level1"] * 100, color=INK, alpha=0.08
    )
    for level in [1, 30, 50, 100, 144, 300, 500]:
        row = df.loc[df["level_index"].eq(level)].iloc[0]
        value = row["reach_vs_level1"] * 100
        ax.scatter(level, value, color=MAUVE if level == 144 else BLUE, s=32, zorder=3)
        offset = (18, -8) if level == 1 else (0, 9)
        alignment = "left" if level == 1 else "center"
        ax.annotate(
            f"M{level}\n{value:.1f}%",
            (level, value),
            xytext=offset,
            textcoords="offset points",
            ha=alignment,
            va="center" if level == 1 else "bottom",
            fontsize=8,
            color=INK,
        )
    ax.set_title(
        "Độ tiếp cận quan sát giảm mạnh theo màn",
        loc="left",
        fontweight="bold",
        color=INK,
    )
    ax.set_xlabel("Thứ tự màn")
    ax.set_ylabel("Độ tiếp cận so với màn 1 (%)")
    ax.set_xlim(1, 500)
    ax.set_ylim(0, 106)
    ax.spines[["top", "right"]].set_visible(False)
    save(fig, "01_progression_reach.png")


def plot_difficulty(df):
    shown = df[df["level_index"] <= 320]
    candidates = shown[shown["is_candidate"]]
    priorities = shown[shown["is_priority"]]
    fig, ax = plt.subplots(figsize=(10.8, 4.6))
    ax.plot(
        shown["level_index"],
        shown["non_win_rate"] * 100,
        color=GRAY,
        linewidth=1.2,
        label="Tỷ lệ không thắng",
    )
    ax.plot(
        shown["level_index"],
        shown["local_non_win_median"] * 100,
        color=BLUE,
        linewidth=2,
        label="Trung vị lân cận (±4 màn)",
    )
    ax.scatter(
        candidates["level_index"],
        candidates["non_win_rate"] * 100,
        color=LAVENDER,
        edgecolor=INK,
        linewidth=0.5,
        s=33,
        label=f"{len(candidates)} màn nghi vấn theo IQR",
        zorder=3,
    )
    ax.scatter(
        priorities["level_index"],
        priorities["non_win_rate"] * 100,
        color=MAUVE,
        marker="*",
        s=125,
        label="Nhóm ưu tiên",
        zorder=4,
    )
    for level in [107, 109, 144, 304]:
        row = shown.loc[shown["level_index"].eq(level)].iloc[0]
        ax.annotate(
            f"M{level}",
            (level, row["non_win_rate"] * 100),
            xytext=(3, 8),
            textcoords="offset points",
            fontsize=8,
            color=INK,
            fontweight="bold",
        )
    ax.set_title(
        "Độ khó có các điểm tăng bất thường so với lân cận",
        loc="left",
        fontweight="bold",
        color=INK,
    )
    ax.set_xlabel("Thứ tự màn")
    ax.set_ylabel("Tỷ lệ không thắng (%)")
    ax.set_xlim(1, 320)
    ax.set_ylim(0, 105)
    ax.legend(ncol=4, loc="upper left")
    ax.spines[["top", "right"]].set_visible(False)
    save(fig, "02_difficulty_local_benchmark.png")


def plot_priorities(df):
    priority = df[df["is_priority"]].sort_values("level_index")
    levels = [f"M{int(x)}" for x in priority["level_index"]]
    panels = [
        ("excess_non_win", "Độ khó tăng bất thường", "Điểm %", 100),
        ("transition_excess", "Khả năng đi tiếp xấu hơn lân cận", "Điểm %", 100),
        ("retention_loss", "Tỷ lệ quay lại thấp hơn lân cận", "Điểm %", 100),
    ]
    base_rate_columns = {
        "excess_non_win": ("non_win_rate", "local_non_win_median"),
        "transition_excess": ("transition_drop_24h", "local_transition_median"),
        "retention_loss": ("next_day_return_rate", "local_return_median"),
    }
    fig, axes = plt.subplots(1, 3, figsize=(10.8, 3.9))
    for ax, (metric, title, ylabel, multiplier) in zip(axes, panels):
        values = priority[metric].to_numpy() * multiplier
        bars = ax.bar(levels, values, color=[BLUE, LAVENDER, MAUVE], width=0.62)
        ax.set_title(title, fontweight="bold", color=INK)
        ax.set_ylabel(ylabel)
        ax.set_ylim(0, max(values) * 1.48)
        ax.spines[["top", "right"]].set_visible(False)
        current_metric, local_metric = base_rate_columns[metric]
        current = priority[current_metric].to_numpy() * multiplier
        local = priority[local_metric].to_numpy() * multiplier
        deltas = current - local
        labels = [
            f"{cur:.1f}% vs {base:.1f}%\n({delta:+.1f}pp)"
            for cur, base, delta in zip(current, local, deltas)
        ]
        ax.bar_label(bars, labels=labels, padding=3, fontsize=7.5)
    fig.suptitle(
        "Ba màn ưu tiên có đặc điểm kinh doanh khác nhau",
        x=0.06,
        ha="left",
        fontweight="bold",
        color=INK,
        fontsize=12,
    )
    fig.tight_layout(rect=[0, 0, 1, 0.92])
    save(fig, "03_priority_business_signals.png")


def plot_resource_comparison(resource_summary):
    groups = ["Không dùng\nvật phẩm", "Có dùng\nvật phẩm"]
    summary = resource_summary.set_index("resource_any_group")
    no_resource = {
        "Thắng lần đầu": summary.loc["No resource", "first_attempt_win"] * 100,
        "Đi tiếp 24 giờ": summary.loc["No resource", "transition_24h"] * 100,
        "Quay lại ngày sau": summary.loc["No resource", "next_day_return"] * 100,
    }
    any_resource = {
        "Thắng lần đầu": summary.loc["Any resource", "first_attempt_win"] * 100,
        "Đi tiếp 24 giờ": summary.loc["Any resource", "transition_24h"] * 100,
        "Quay lại ngày sau": summary.loc["Any resource", "next_day_return"] * 100,
    }
    group_order = ["No resource", "Any resource"]
    payer_rates = summary.loc[group_order, "payer_rate_24h"].to_numpy() * 100
    revenues = summary.loc[group_order, "iap_revenue_per_user_24h"].to_numpy()
    metrics = list(no_resource)
    x = np.arange(len(metrics))
    width = 0.35
    fig = plt.figure(figsize=(10.8, 4.2))
    grid = fig.add_gridspec(1, 3, width_ratios=[2.4, 1, 1], wspace=0.42)
    ax1 = fig.add_subplot(grid[0, 0])
    bars1 = ax1.bar(
        x - width / 2,
        list(no_resource.values()),
        width,
        color=GRAY,
        label=groups[0].replace("\n", " "),
    )
    bars2 = ax1.bar(
        x + width / 2,
        list(any_resource.values()),
        width,
        color=BLUE,
        label=groups[1].replace("\n", " "),
    )
    ax1.set_xticks(x, metrics)
    ax1.set_ylim(0, 108)
    ax1.set_ylabel("Tỷ lệ (%)")
    ax1.set_title("Tiến trình và tỷ lệ quay lại", fontweight="bold", color=INK)
    ax1.legend(loc="upper center", bbox_to_anchor=(0.5, -0.18), ncol=2, fontsize=7)
    ax1.bar_label(
        bars1, labels=[f"{v:.1f}%" for v in no_resource.values()], padding=2, fontsize=8
    )
    ax1.bar_label(
        bars2,
        labels=[f"{v:.1f}%" for v in any_resource.values()],
        padding=2,
        fontsize=8,
    )
    ax1.spines[["top", "right"]].set_visible(False)

    ax2 = fig.add_subplot(grid[0, 1])
    bars = ax2.bar(groups, payer_rates, color=[GRAY, BLUE], width=0.62)
    ax2.set_title(
        "Người trả tiền\ntrong 24 giờ", fontweight="bold", color=INK, fontsize=10
    )
    ax2.set_ylabel("Tỷ lệ (%)")
    ax2.set_ylim(0, 5.5)
    ax2.bar_label(
        bars, labels=[f"{value:.1f}%" for value in payer_rates], padding=3, fontsize=9
    )
    ax2.spines[["top", "right"]].set_visible(False)

    ax3 = fig.add_subplot(grid[0, 2])
    bars = ax3.bar(groups, revenues, color=[GRAY, BLUE], width=0.62)
    ax3.set_title(
        "Doanh thu mua hàng/người\ntrong 24 giờ",
        fontweight="bold",
        color=INK,
        fontsize=9,
    )
    ax3.set_ylabel("USD/người")
    ax3.set_ylim(0, 0.68)
    ax3.bar_label(
        bars, labels=[f"${value:.2f}" for value in revenues], padding=3, fontsize=9
    )
    ax3.spines[["top", "right"]].set_visible(False)

    fig.suptitle(
        "Màn 109: hành trình và mua hàng theo nhóm dùng vật phẩm",
        x=0.06,
        ha="left",
        fontweight="bold",
        color=INK,
        fontsize=12,
    )
    fig.subplots_adjust(top=0.80, bottom=0.25)
    save(fig, "04_level109_resource_tradeoff.png")


def main():
    """Create report figures from the saved analysis table."""
    ASSETS.mkdir(parents=True, exist_ok=True)
    df = pd.read_csv(DATA)
    resource_summary = pd.read_csv(ROOT / "data" / "level_109_resource_summary.csv")

    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 9,
            "axes.titlesize": 12,
            "axes.labelsize": 9,
            "axes.edgecolor": "#C4D5E5",
            "axes.linewidth": 0.8,
            "axes.grid": True,
            "grid.color": "#E8F0F8",
            "grid.linewidth": 0.7,
            "legend.frameon": False,
        }
    )

    plot_progression(df)
    plot_difficulty(df)
    plot_priorities(df)
    plot_resource_comparison(resource_summary)
    print(f"Created report charts in {ASSETS}")


if __name__ == "__main__":
    main()
