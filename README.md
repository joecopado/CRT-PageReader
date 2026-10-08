# CRT page reader: a starting point for the Test Agent's page parser

A Salesforce page is mostly header, navigation and hidden markup. This repository is a parser that **scrubs a page of its
uninteresting parts** and gives the Test Agent only the controls that matter, each with the exact keyword call to use. It is
wrapped in three Robot keywords (`Gz Read Page`, `Gz Show`, `Gz Verify`) and one test file that runs them on a real page and
explains every step. It is for the developers of the CRT Test Agent, as something to read, run and take apart.

Start with `tests/how-the-page-reader-works.robot`: its header comment and its Documentation are the explanation.

## What is in it

| Path | What it is |
|---|---|
| `tests/how-the-page-reader-works.robot` | The explanation and four test cases: what the page is to the parser; what the AI is given; search instead of read; act, then verify by meaning. |
| `resources/garzai_page_reader.py` | The three keywords and the plan builder behind them. |
| `resources/garzai_parser_walkthrough.py` | Six keywords that show the pipeline one stage at a time. |
| `resources/garzai_parser/` | The parser bundle the reader imports: capture, parse, classify, templates. `MANIFEST.json` lists it. |
| `resources/garzai_navigation.robot` | URL-first navigation (`Open Nav Tab` is the one used). |
| `resources/common.robot`, `resources/page_reader_steps.robot` | Written for this repository: imports, `Setup Browser`, `End suite`, and two plain-sentence keywords. |
| `SOURCE-HASHES.txt` | sha256 of every copied file. `shasum -a 256 -c SOURCE-HASHES.txt` |
| `LICENSE-beautifulsoup4.txt` | Licence text of Beautiful Soup 4.15.0, the version vendored in the bundle. |

Every file in `SOURCE-HASHES.txt` (65) is byte-identical to the same path in CRTPagePatterns at commit `6f147e6`, the
repository this was taken from. Left out because the reader does not need them: the page-object store of recorded locators
(`resources/garzai_pom/`). The parser bundle is shipped whole, exactly as its generator writes it.

## Variables CRT must define

The cases log in to a Salesforce developer org that holds the custom "Zoo Nightmare Inputs" tab, using the JWT bearer flow.
Define these three as project or robot variables in the CRT job (names exactly; values are never in this repository):

    ${client_idSlock}    ${usernameSlock}    ${private_keySlock}

`${BROWSER}` defaults to `chrome` in `resources/common.robot`.

## How to run it

* **In CRT:** a job whose repository is this one, test file `tests/how-the-page-reader-works.robot`, the three variables above.
  Run the cases in file order: case 1 first. In a CRT build (not Live Testing) `Gz Walk Capture` installs `lxml` for the run
  if the container lacks it and says so on the console; `Gz Read Page` needs it too.
* **In Live Testing:** run `Suite Setup` lines, then a case at a time. Case 4 types one value (`25000`) into a field and saves
  nothing.
* **Locally:** the cases need CRT's licensed QForce library, so they cannot run on a laptop. A syntax and keyword check does:
  `robot --dryrun tests/how-the-page-reader-works.robot` with a stand-in library named `QForce` on the Python path. The
  reader and parser themselves run offline over a stored HTML capture (`garzai_page_reader.build_plan(html)`; Python 3.10 or
  newer with `lxml` and `typing_extensions` installed).

Nothing in this suite clicks Save, Delete or Submit.

## Status, stated plainly

Each case in the test file is labelled `PROVEN` (a run read the result back; date and what ran are given) or `NOT-YET-RUN`.
As packaged in this repository the suite has had a dry run only. The same keywords have run in CRT builds and in the CRT
editor; read the labels before relying on a line.

**The bundle is current.** It was regenerated on 2026-10-08 from the maintainer's parser with the generator named in
`MANIFEST.json`, which lists every file with the hash of its source, so any later drift shows up as a failed comparison.
CRTPagePatterns carries the same bundle. Before shipping it, the old and new bundles were scored on the same 10 stored
pages: the Zoo Nightmare Inputs page this suite uses read identically; elsewhere unlabelled table rows dropped from 69 to
5 on one page, and anchors were kept only where a label repeats.

## Third-party code and licences

| Component | Where | Licence |
|---|---|---|
| Beautiful Soup 4, 4.15.0 | `resources/garzai_parser/tools/interop/resources/pythonDom/vendor/bs4/` | MIT (notice in each file; text in `LICENSE-beautifulsoup4.txt`) |
| Soup Sieve, 2.9.1 | `resources/garzai_parser/tools/interop/resources/pythonDom/vendor/soupsieve/` | MIT (full notice in `soupsieve/__init__.py`) |
| lxml | not included; installed with pip for the run if missing | BSD-3-Clause |
| QWeb, QForce | not included; provided by CRT (QForce is licensed) | their own licences |

The vendored files are unmodified, notices intact.

## Where the full project lives

CRTPagePatterns, the page-pattern project this repository was cut from.
