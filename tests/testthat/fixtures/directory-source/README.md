# NJDOE directory byte excerpts

These are offline parser fixtures, never directory cache inputs. CSV bytes and
line endings are copied unchanged from NJDOE downloads captured September 30,
2026. All fixtures retain the three introduction lines and source column names.

- Source district CSV: https://homeroom4.doe.nj.gov/public/districtpublicschools/download/
  SHA-256 `51a62cc3b0967be4bce814abc311b5156730ba4cefb17b46da00d995d062273b`.
  Local capture completed at approximately `2026-09-30T03:58:07Z`.
- Source school CSV: https://homeroom4.doe.nj.gov/public/publicschools/download/
  SHA-256 `636918752bcc3fc1deab82f4b7df400fb03a83fcf23e65e5e39fa9f997c524ca`.
  Local capture completed at approximately `2026-09-30T03:57:42Z`.

`hainesport-malformed.csv` contains source lines 130–132. Line 131, district
051910, has 54 fields against 53 column names: the SEC surname `Procopio, Jr.`
is unquoted. A standard CSV reader consequently puts `Jr.` in SEC Title2 and
shifts subsequent columns. `robeson-malformed.csv` contains lines 375–377.
Line 376, district 806025, has 55 fields against 53 column names, with extra
empty address fields before Phone; the personnel fields consequently shift.
Neither row is repaired by guessing column positions. Both fail structural
validation before any personnel assignments are built.

`district-valid.csv` contains unchanged district lines 130, 132 and 377.
`school-slot-titles.csv` contains all 16 source rows with Princ. Title 2 exactly
`Director` (15) or `Education Coordinator` (1). These are verbatim titles in
a school contact slot; the slot alone does not prove that these jobs are
principals. They remain canonical `other` pending authoritative role evidence.
The official district/school index pages returned Imperva challenges during
this investigation, so no alternative structured extraction was verified.
