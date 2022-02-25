from typing import Tuple

import geopandas as gpd
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from matplotlib.colors import Colormap
from matplotlib.lines import Line2D
from matplotlib.offsetbox import AnchoredText

PADDING = 0.005


def prepare_axes(ax: plt.Axes, cycles_info: pd.DataFrame) -> Tuple[float, float, float, float]:
    min_y = cycles_info["lat"].min() - PADDING
    max_y = cycles_info["lat"].max() + PADDING
    min_x = cycles_info["lon"].min() - PADDING
    max_x = cycles_info["lon"].max() + PADDING
    ax.set_ylim((min_y, max_y))
    ax.set_xlim((min_x, max_x))
    ax.set_axis_off()
    return min_x, max_x, min_y, max_y


def save_fig(fig: plt.Figure) -> str:
    fig.patch.set_facecolor("white")
    map_file = "/tmp/map.png"
    fig.savefig(map_file)
    return map_file


def set_custom_legend(ax: plt.Axes, cmap: Colormap) -> None:
    values = [(0.0, "Empty"), (0.5, "Busy"), (1.0, "Full")]
    legend_elements = []
    for gradient, label in values:
        color = cmap(gradient)
        legend_elements.append(
            Line2D(
                [0],
                [0],
                marker="o",
                color="w",
                label=label,
                markerfacecolor=color,
                markeredgewidth=0.5,
                markeredgecolor="k",
            )
        )
    ax.legend(handles=legend_elements, loc="upper left", prop={"size": 6}, ncol=len(values))


def plot_map(cycles_info: pd.DataFrame, version: str) -> str:
    fig = plt.Figure(figsize=(6, 4), dpi=200, frameon=False)
    ax = plt.Axes(fig, [0.0, 0.0, 1.0, 1.0])
    fig.add_axes(ax)

    min_x, max_x, min_y, max_y = prepare_axes(ax, cycles_info)

    # Get external resources
    cmap = plt.get_cmap("OrRd")
    london_map = gpd.read_file("shapefiles/London_Borough_Excluding_MHW.shp").to_crs(epsg=4326)

    # Plot elements
    ax.fill_between([min_x, max_x], min_y, max_y, color="#9CC0F9")
    london_map.plot(ax=ax, linewidth=0.5, color="#F4F6F7", edgecolor="black")
    sns.scatterplot(
        y="lat", x="lon", hue="proportion", edgecolor="k", linewidth=0.1, palette=cmap, data=cycles_info, s=25, ax=ax
    )

    text = AnchoredText(f"Tweeting lambda, version {version}", loc=4, prop={"size": 5}, frameon=True)
    ax.add_artist(text)

    set_custom_legend(ax, cmap)

    map_file = save_fig(fig)

    return map_file
