import geopandas as gpd
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from matplotlib.axes import Axes
from matplotlib.figure import Figure


PADDING = 0.005


def prepare_axes(ax: Axes, cycles_info: pd.DataFrame) -> None:
    min_y = cycles_info["lat"].min() - PADDING
    max_y = cycles_info["lat"].max() + PADDING
    min_x = cycles_info["lon"].min() - PADDING
    max_x = cycles_info["lon"].max() + PADDING
    ax.axis("off")
    ax.get_legend().remove()
    ax.set_title("London cycles")
    ax.set_ylim((min_y, max_y))
    ax.set_xlim((min_x, max_x))


def save_fig(fig: Figure) -> str:
    fig.tight_layout()
    fig.patch.set_facecolor("white")
    map_file = "/tmp/map.png"
    plt.savefig(map_file)
    return map_file


def plot_map(cycles_info: pd.DataFrame) -> str:
    london_map = gpd.read_file("shapefiles/London_Borough_Excluding_MHW.shp").to_crs(epsg=4326)

    fig = plt.figure(figsize=(6, 4), dpi=170)
    ax = fig.gca()

    london_map.plot(ax=ax)
    sns.scatter(y="lat", x="lon", hue="proportion", palette="Blues", data=cycles_info, s=25, ax=ax)

    prepare_axes(ax, cycles_info)

    map_file = save_fig(fig)

    return map_file
