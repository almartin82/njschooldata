# The Head First Analyst's Guide to NJ TGES

### or: every number in this dataset has an asterisk, and your job is knowing where they hide

The Taxpayers' Guide to Education Spending looks like a gift. Per-pupil dollars for
every district, sliced into twenty-odd categories, going back to 2001, downloadable
as a zip. Drop it into a bar chart and you have a story by lunch.

That is exactly how people publish confident nonsense.

Almost every headline figure in TGES carries an accounting caveat that, if you miss
it, flips your conclusion. Not a rounding caveat. A "you compared two things that
aren't the same thing" caveat. This guide is a tour of those caveats. Read it before
you put a TGES number in front of anyone who matters.

We'll start with the one you already found.

---

## The warm-up you already know: pension is invisible here

You wanted per-district teacher pension cost. Reasonable. NJ pays TPAF pension,
post-retirement medical, and the employer share of social security on behalf of
districts, so none of it lands in a district's own budget. It is excluded from the
headline Budgetary Per Pupil Cost, folded silently into Total Spending Per Pupil, and
itemized in neither.

The reason you can't back into it by subtraction is the thing worth keeping in your
pocket, because it repeats all over this dataset. The spending numbers are gross
expenditures. The aid numbers are revenue. They live on opposite sides of the ledger.
Subtracting transportation aid from a spending residual is not a smaller estimate of
pension, it is a category error that happens to return a number. The only file that
itemizes the pension expenditure is AudSum, and that same file hands you pension
directly, so the subtraction never buys you anything.

Hold onto that ledger distinction. Here are ten more.

---

## Nugget 1: There is no such thing as "per-pupil spending"

There are at least three, and they differ by thousands of dollars.

**Budgetary Per Pupil Cost** (CSG1) is the number NJ wants you to compare across
districts. It deliberately strips out transportation, capital, debt service, tuition
to other districts, food service, federal grants, and the on-behalf pension. Think of
it as "what it costs to run our own classrooms."

**Total Spending Per Pupil** (CSG1AA / VITSTAT) adds all of that back. For a typical
district it runs five to seven thousand dollars higher than budgetary cost.

The individual category lines (CSG2 through CSG15) are a third slice again.

When someone says "Newark spends $X per pupil," your first question is always *which*
number. A reporter quoting Total Spending and an administrator quoting Budgetary Cost
are both right, and they are 30 percent apart. `tges_composition()` lays the categories
next to budgetary cost; `tges_excluded_costs()` shows you the gap between budgetary and
total.

---

## Nugget 2: Two of those "per pupil" numbers use different denominators

This is the one that silently breaks cross-district comparisons.

Budgetary Per Pupil Cost divides by resident enrollment. The Total Spending Detail
figures divide by enrollment plus sent pupils. For a district that teaches all its own
kids, those two counts agree within about a percent and nobody gets hurt.

But New Jersey is full of K-6 and K-8 districts that ship their older students to a
neighboring district and pay tuition for the seat. For those districts the two
denominators pull apart. Saddle River's "enrollment plus sent" is 2.67 times its
resident enrollment. Subtract one per-pupil figure from the other for a district like
that and you get garbage, sometimes negative garbage.

Roughly 40 percent of NJ districts are sending districts to some degree, and that
includes big cities placing special-education and vocational students out. That is why
`tges_excluded_costs()` carries a `sent_pupil_share` column and a `residual_reliable`
flag. Throw out the unreliable ones before you do per-pupil arithmetic.

---

## Nugget 3: County Vocational and Special Services districts will eat your rankings

Sort any per-pupil spending column from the top and you will not see Princeton or
Millburn. You will see Salem County Special Services at $56,000 a pupil, Bergen County
Special Service at $92,000, and a long run of county vocational districts.

Those numbers are real and they are not a scandal. Special services districts educate
the students with the most intensive (and most expensive) needs, and they have no
ordinary enrollment to average that cost against. They are a different animal from a
K-12 operating district. Drop them into a "highest spending districts" chart or a
statewide mean and they quietly wreck it.

Segment them out before you rank or average. They announce themselves by name
(`Co Vocational`, `Co Special Service`, `Spec Serv`) and they belong in their own group,
measured against each other.

---

## Nugget 4: Rising per-pupil spending often means falling enrollment

Per-pupil is a ratio. Dollars on top, kids on the bottom. When a district's per-pupil
cost jumps 20 percent over five years, the instinct is "they spent more." Sometimes.
Just as often the denominator shrank: enrollment fell, the building and the principal
and the bus route did not, and the same money spread over fewer students.

Two corrections matter. TGES dollars are nominal, so part of any multi-year rise is
plain inflation. And the denominator moves, so part of it is demographics, not budgets.
A district in real decline and a district genuinely investing can post the identical
per-pupil growth number for opposite reasons. `tges_real_growth()` splits per-pupil
growth into the real-cost piece and the enrollment piece so you don't confuse the two.

---

## Nugget 5: One of the three years didn't happen yet

Each guide reports three years per indicator. Two are actuals. The third is a budgeted
figure, flagged `calc_type = "Budgeted"`. That third year is a plan, drafted before the
year began, and districts miss their budgets routinely.

So two things to avoid. Don't build a time series that splices budgeted years onto
actual years and call it a trend. And don't compare one district's budgeted number
against another's actual. Filter to `calc_type == "Actuals"` for anything historical,
and treat the budgeted column as an intention, useful but separate.

---

## Nugget 6: The rank is a within-peer-group rank, and "1" isn't always good

From 2019 on, a rank ships as `"33|57"`, meaning 33rd out of 57. Out of 57 what? Not the
state. Out of the district's enrollment-band peer group, the `group` column. NJ ranks a
400-student K-6 district against other small K-6 districts, never against Newark. Read
that rank as a statewide standing and you are wrong by construction.

Same column, second trap: rank direction is not consistent. For "classroom instruction
as a share of budget," a high rank flatters. For "administrative cost per pupil," it
does the opposite. There is no global "1 means best." You have to know which way each
indicator points before you write a word about it. When you want a comparison you
control, `tges_percentile_rank()` lets you pick the frame (TGES band, DFG, county, or
statewide) instead of inheriting it.

---

## Nugget 7: The ESSER cliff is hiding inside Total Spending

Federal money (Title I, IDEA, and the enormous one-time ESSER pandemic relief) sits in
the "Grants and Entitlements" line and inside Total Spending Per Pupil. It is not in
Budgetary Cost.

ESSER ran from roughly 2021 to 2024 and then stopped cold. Chart Total Spending Per
Pupil across that window and you will see a bump and a drop that says nothing about how
districts run classrooms and everything about Washington turning a hose on and off.
Districts that propped up recurring costs with that one-time money are at the edge of a
cliff now. For trend work across the pandemic years, prefer Budgetary Cost or split the
federal piece out explicitly. If the cliff itself is your question,
`tges_federal_exposure()` screens it off the VITSTAT federal-revenue share.

---

## Nugget 8: A district's state aid tells you almost nothing about its spending

Now that `fetch_state_aid()` exists, the temptation is "high aid, high spending." It is
backwards. New Jersey's equalization aid is built to fill the gap between what a district
can raise locally and what the state says it needs. Poor districts draw large
equalization aid. Wealthy districts draw close to nothing and fund their (often higher)
spending straight out of local property taxes.

So Newark pulls more than a billion dollars in equalization aid, while a wealthy shore
town pulls almost none and still outspends it per pupil. Aid is an input keyed to local
wealth, not a measure of resources or generosity. Don't read spending off aid, or aid
off spending. Different questions, and the aid file is the revenue ledger again, not the
spending one.

---

## Nugget 9: "TGES 2025" is not 2025 data

This one bites everybody once. The guide published under a given year reports the two
prior fiscal years as actuals plus the current year as a budget. The 2025 guide's
audited numbers are fiscal 2023 and 2024. The Total Spending Detail workbook literally
named `Detail_FY24` lives inside the 2025 bundle and describes school year 2023-24.

In package terms, `fetch_tges(2025)` returns rows stamped `end_year` 2023 and 2024
(actuals) and 2025 (budgeted). Label a chart "2025 spending" because you called
`fetch_tges(2025)` and you are off by a year or two. Trust the `end_year` on the row, not
the argument you passed in.

---

## Nugget 10: Half the rows aren't districts, and district codes repeat

Two data-hygiene landmines in one.

TGES ships group-average and statewide-average rows mixed in with the real districts.
They carry a missing or sentinel code (`NA` or `"00NA"`). Leave them in and your district
count is inflated and your statewide mean is an average of averages. The analysis helpers
run everything through an internal real-districts filter for exactly this; on raw
`fetch_tges()` output you have to do it yourself.

And the four-digit district code is unique only within a county. The same code turns up
in several counties. Join two TGES tables on `district_id` alone and you will silently
weld Atlantic's 0010 to some other county's 0010. Key on county plus district code, every
time. (We hit this exact bug joining the spending detail to CSG1.)

---

## Lightning round

A few more that didn't need a full page.

Median teacher salary (CSG16-18) is not compensation. It leaves out benefits and, yes,
the state-paid pension again, so a district that looks cheap on salary can be expensive
on total cost and you won't see it here.

The SDA debt service inside Total Spending is the state's borrowing. For the old Abbott
districts, Total Spending includes an estimate of debt service the state pays on school
construction bonds. It counts in the total, but it isn't local spending.

A thin fund balance can be deliberate. NJ caps general-fund surplus near 2 percent, so a
low or falling balance is sometimes a planned spend-down rather than distress.
`tges_fund_balance_health()` flags the excess-surplus and the declining-balance cases
separately so you don't read one as the other.

"N.R." and "N.A." are not zero. Not Reported and Not Applicable become `NA` in the tidy
output. Treat them as missing. Score them as 0 and you will drag every average down with
phantom districts.

---

## The one-page cheat sheet: which number do I use?

| Your question | Use | Don't forget |
|---|---|---|
| How efficiently does a district run its classrooms vs peers? | Budgetary Per Pupil Cost + category lines (CSG1-15), within one enrollment band | Rank is within-group; direction flips by indicator |
| What does it truly cost to educate a kid here? | Total Spending Per Pupil (CSG1AA / VITSTAT) | Includes state-paid pension, SDA debt, and one-time federal grants |
| How has spending changed over time? | Actuals only, deflated to real dollars | Separate the enrollment-denominator effect |
| Anything about teacher pension | Not TGES. AudSum, by data request | The on-behalf TPAF line is itemized only there |
| State aid by category | `fetch_state_aid()` | Aid is revenue keyed to local wealth, not spending |

The through-line: TGES packs a comparative cost measure, a total-spending measure, a
revenue measure, and a budget plan into the same friendly spreadsheet, on two different
denominators, with averages hiding among the districts. Figure out which one you're
holding before you divide it by anything.
