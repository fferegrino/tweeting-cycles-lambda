from datetime import datetime
from typing import List

import pandas as pd
from tfl.api import bike_point
from tfl.api.presentation.entities.additional_properties import AdditionalProperties


def get_number(additional_properties: List[AdditionalProperties], key: str) -> int:
    [nb] = [prop.value for prop in additional_properties if prop.key == key]
    return int(nb)


def download_cycles_info() -> pd.DataFrame:
    all_bike_points = bike_point.all()
    query_time = datetime.now()
    data = []

    for place in all_bike_points:
        bikes = get_number(place.additionalProperties, "NbBikes")
        empty_docks = get_number(place.additionalProperties, "NbEmptyDocks")
        docks = get_number(place.additionalProperties, "NbDocks")
        data.append(
            (
                place.id,
                place.commonName,
                place.lat,
                place.lon,
                bikes,
                empty_docks,
                docks,
            )
        )

    data_df = pd.DataFrame(
        data, columns=["id", "name", "lat", "lon", "bikes", "empty_docks", "docks"]
    ).set_index("id")
    data_df["query_time"] = pd.to_datetime(query_time).floor("Min")
    data_df["proportion"] = (data_df["docks"] - data_df["empty_docks"]) / data_df["docks"]

    return data_df
