#import "@local/standalone:0.1.0": *

#show: standalone.with(width: 14cm)

#table(
  columns: (2fr, 1fr, 1fr),
  align: (left, right, right),
  inset: (x: 6pt, y: 3.5pt),
  stroke: none,
  table.hline(stroke: 0.8pt),
  table.header([Indicator], [2020], [2025]),
  table.hline(stroke: 0.45pt),
  [Productivity], [100], [114],
  [Investment / GDP], [18.4%], [23.7%],
  table.hline(stroke: 0.8pt),
)
