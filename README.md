# Torque-log-visualizer-excel
For torque-bhp app. this repo contains a perl script that converts tracklog.csv into excel csv.
The excel sheet visualizes this csv.
usage:
copy the converted csv into the excel first tab.

On the second tab you can configure scope area, what to see, statistics
with filling yellow fields.

there are two graphs with 4 column data
and a 2 dimensional GPS graph with track data.
Statistics of columns sum, min, max, average of the selected column.

converter works with hungarian locale. Uses comma instead of decimal point.
script must be edited (convertnumber subroutine) if no number conversion needed.

tracklog.csv can be converted by other tool if you dont want to run perl script.

different log header in one file is not supported.

This repo is a raw version, for intermediate knowledge users.
further improvement can be the perl sctipt is to be integrated into excel vba macro
with a csv importer button.


