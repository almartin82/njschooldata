# Retained SPR profile observations

`retained-spr.rds` contains faithful subsets of public fetcher outputs from the
original NJ DOE district SPR workbooks for 2022–2025. Every column is retained,
including native entity identifiers, source school-year labels, percentages,
published zeroes and independently suppressed counts. Districts are Newark
(3570), South Orange–Maplewood (4900), Absecon (0010) and Academy Charter High School (6010); statewide records are retained for source comparisons.

`SOURCE.json` records original parent byte lengths and SHA-256 values and the
replay scripts. The original parents remain external retained cache files;
this fixture is a parser-output regression subset, not production coverage or
new acquisition evidence. Acquisition identity and original retrieval clocks
were not asserted from legacy filesystem timestamps. No fixture values were
invented or converted into an original-source-shaped workbook.
