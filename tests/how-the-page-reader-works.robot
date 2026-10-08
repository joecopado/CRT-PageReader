# =====================================================================================================================
# HOW THE PAGE READER WORKS -- read this block first; the suite Documentation below is the same story in the Robot log.
#
# WHO IT IS FOR: developers of the CRT Test Agent. They asked for a parser that scrubs a Salesforce page of its
# "uninteresting" parts, as a starting point. This repository is that parser and the three keywords that wrap it.
# Nothing here is new code written for the occasion: every file listed below is a byte-for-byte copy of a file in
# CRTPagePatterns (commit b69ac74), except the files marked WRITTEN HERE and the files marked NOT COPIED.
#
# THE FILE MAP (this repository, and nothing else)
#
#   README.md                          One page: what this is, the variables CRT must define, how to run it.
#   SOURCE-HASHES.txt                  sha256 of every copied file. Check with:  shasum -a 256 -c SOURCE-HASHES.txt
#   LICENSE-beautifulsoup4.txt         NOT COPIED FROM THE BUNDLE: the licence text shipped with Beautiful Soup 4.15.0, the
#                                      same version as the vendored copy (the vendored files carry only a one-line notice).
#   .gitignore                         WRITTEN HERE. Two lines: python caches and Robot output.
#
#   tests/how-the-page-reader-works.robot
#                                      WRITTEN HERE. This file: the explanation and four test cases that run the reader.
#
#   resources/common.robot             WRITTEN HERE (reduced). Imports QWeb, QForce and the page reader; defines
#                                      Setup Browser and End suite, whose executable lines are CRTPagePatterns' own.
#   resources/page_reader_steps.robot  WRITTEN HERE. Two plain-sentence keywords the test cases use:
#                                      Open The Zoo Nightmare Inputs Page, Read Every Page Of The Plan And Measure It.
#   resources/garzai_navigation.robot  Copied. URL-first navigation. Only Open Nav Tab (and the three small keywords it
#                                      calls) is used here; the others come along because the file is copied unmodified.
#   resources/garzai_page_reader.py    Copied. THE THREE KEYWORDS: Gz Read Page, Gz Show, Gz Verify (class
#                                      garzai_page_reader), and the plan builder behind them (build_plan, derived_call,
#                                      ladder, store_answer, render_page, judge). It imports the parser bundle lazily.
#   resources/garzai_parser_walkthrough.py
#                                      Copied. Six keywords that show the pipeline one stage at a time: Gz Walk Capture,
#                                      Gz Walk Parse, Gz Walk Calls, Gz Walk Pages Total, Gz Walk Plan Size, Gz Walk
#                                      Summary. They call the page reader's own functions and re-implement nothing.
#
#   resources/garzai_parser/           Copied, 58 of the bundle's 62 files (see NOT COPIED below). The code the reader imports.
#     MANIFEST.json                    The bundle's own list: what is in it, the entry module, a sha256 per file, and when it
#                                      was built. It still names the four template files that are NOT COPIED.
#     tools/recorder/crt_override/compose_live.py
#                                      THE ENTRY MODULE. The reader uses live_capture (capture the open page),
#                                      parse_capture (parse a capture), _fingerprint (has the page changed?),
#                                      split_step_body, sentinel_landed. The rest of this 3,000-line file composes
#                                      recorder lines and is not used by the reader.
#     tools/dom-miner/cdp_capture.py   build_serializer: the JavaScript that runs in the page and writes it out as HTML,
#                                      shadow roots included. This is where hidden subtrees are dropped.
#     tools/recorder/review_table.py   Capture + build_rows: turns the parser's elements into one row per control (label,
#                                      family, repeat index, relative xpath ladder, region page-or-chrome). region_of is
#                                      the chrome rule.
#     tools/recorder/parser_gateway.py, disambiguation_args.py, crt_override/descriptor.py
#                                      Small helpers: call the parser by name at call time; turn a repeat index into
#                                      QWeb's numeric anchor; describe an element.
#     tools/recorder/pom/              The page-object store READER (store, consult, match, scope, keys, export_flow):
#                                      looks up locators that already passed live, splits an open modal from the page
#                                      behind it, and names a page from its URL. This repository ships no store.
#     tools/interop/resources/pythonDom/
#                                      THE PARSER: capture_orchestration.py (parse_elements_from_html, the entry),
#                                      component_classifier.py (what family a tag is), element_compiler.py (its label and
#                                      its call), dom_config.py (reads the template JSON, _is_noise), text_engine.py,
#                                      iframe_descent.py; vendor/ holds the HTML parser it uses (bs4, soupsieve; MIT).
#     docs/recorder/templates/         The schema-driven rules, one JSON per platform: salesforce-lightning.json is the one
#                                      used on a Salesforce page; web-generic.json on any other.
#     docs/recorder/patterns/library.json
#                                      Named control shapes the rows are stamped with (the parser module that loads it is
#                                      imported at start-up).
#     tools/qforce-lite/confirm.py     lenient_equal: the compare-by-meaning that Gz Verify uses.
#     tools/qforce-lite/{predict,chains,text_match}.py, discovery/*.py, tools/benchmark/metrics.py,
#     tools/recorder/{pattern_library,pom_asset,metadata_dom_parity}.py
#                                      Imported by the modules above (metadata_dom_parity.py is imported by
#                                      review_table.py). The page reader does not call them directly.
#
# NOT COPIED, because the reader does not need them:
#   resources/garzai_pom/              The page-object store (recorded locators per page). The reader looks for it beside
#                                      itself (pack_dir) and, when absent, says so and derives every call from the page.
#   four of the bundle's templates     salesforce-lightning.v2.json, salesforce-lightning.v3.json, web-generic.v3.json,
#                                      react-virtualized.json. The default template selection never picks them.
#
# THE CASES BELOW AND HOW HONEST THEY ARE
#   # PROVEN:       a run read back the result; the date and what ran are stated. The records of those runs are kept by the
#                   maintainer and are not part of this repository.
#   # NOT-YET-RUN:  nothing has shown it. Read these before you rely on the line.
#
# ONE HONEST NOTE ABOUT THE PARSER BUNDLE
#   resources/garzai_parser is a SNAPSHOT: MANIFEST.json says generated 2026-09-23T11:16:49 (plus two files added later,
#   confirm.py and pom/export_flow.py). The maintainer's current parser has moved on: a drift check run on 2026-10-08
#   finds 2 of 6 modules and 4 of 6 templates identical to it; the vendored bs4 and soupsieve are identical. The bundle will
#   be regenerated after the 2026-10-08 demo with the generator named in MANIFEST.json. So read the SHAPE of the pipeline
#   here, not the last detail of any one rule.
# =====================================================================================================================
*** Settings ***
Documentation             HOW THE PAGE READER WORKS -- a guided tour for the developers of the CRT Test Agent.
...
...                       WHAT IT IS. A parser that scrubs a Salesforce page of its uninteresting parts and hands the Test
...                       Agent only the controls that matter, each with the exact keyword call to use. It is wrapped in three
...                       keywords: Gz Read Page, Gz Show, Gz Verify. The four test cases below run it on one real page and
...                       print what happens, step by step. Every claim in this text is taken from the code in this repository;
...                       the function that does it is named beside it.
...
...                       THE PROBLEM. The Test Agent's own read_page hands the model the first 40,000 characters of a 99 KB
...                       list. Measured on the page used below (2026-10-01): the list held 78 elements, 24 of them the
...                       Salesforce header and navigation, 46 of them ghosts of a hidden sibling tab that Lightning keeps
...                       mounted, and only 6 the page's own inputs, none with a readable label. The model got the first
...                       40,000 characters: header, then ghosts. 34 elements never reached it. Searching the page for the
...                       controls that matter, instead of reading all of it, is what these keywords do.
...
...                       THE PIPELINE. Six steps. Gz Walk Capture, Gz Walk Parse, Gz Walk Calls and Gz Read Page show the
...                       first five in the log.
...
...                       1. CAPTURE. compose_live.live_capture runs, in one round trip, the JavaScript from
...                       cdp_capture.build_serializer inside the open page. The serializer walks every element's child nodes,
...                       and where an element has an open shadowRoot it writes that root out first as a template element.
...                       Lightning's synthetic shadow DOM is ordinary light DOM, so this sees it too. Same-origin iframes
...                       are written inline; a cross-origin frame is left as a marker comment. Secrets in text and
...                       attributes (session ids, tokens, org ids, private keys) are replaced by REDACTED.
...
...                       2. PARSE. compose_live.parse_capture hands the capture to review_table.build_rows, which calls
...                       capture_orchestration.parse_elements_from_html. dom_config.select_template picks the template:
...                       the one named by the environment variable GARZAI_DOM_TEMPLATE if it is set; otherwise
...                       docs/recorder/templates/salesforce-lightning.json when any of its frameworkMarkers (lightning-,
...                       lwc-, data-aura-rendered-by, data-aura-class, slds-) appears in the capture, otherwise
...                       web-generic.json. All platform rules live in that JSON; the Python holds only fallbacks. The parser
...                       reads the page with the vendored bs4 and emits a list of elements, each with a family
...                       (component_classifier), a label and the source of that label (element_compiler) and, for a label
...                       that repeats, its position among the same-label controls. The label is the first source in the
...                       template's labelPrecedence that yields text: inner_text (the visible text), aria_label,
...                       standard_label, aria_labelledby, form_element_label, placeholder, title_attr, sibling_label_text,
...                       label_span, and last assistive_text.
...
...                       3. CLASSIFY AND COMPOSE THE CALL. review_table.build_rows turns each element into a row: label,
...                       family, repeat index and group size, the parser's anchor candidates, its region (region_of: page or
...                       chrome), an identity xpath and a relative xpath ladder (xpath_ladder). Then the page reader's
...                       build_plan composes the call. derived_call returns ClickItem with an explicit tag when the parser's
...                       own first call for the control is ClickItem by a stable attribute; otherwise the keyword for the
...                       family (stock_kw) with the control's label; when the control has no visible label, a relative xpath.
...                       ladder() lists the further rungs. An anchor is added only for member 2 or later of a repeated
...                       label (_anchor_kwargs). Absolute or positional xpaths are never offered (relative_xpaths,
...                       is_positional_xpath). If a page-object store is present and holds a locator that already passed
...                       live for the control (store_answer), that locator leads and the line is marked verified. This
...                       repository ships no store, so every call is derived from the page.
...
...                       4. WHAT IS DROPPED AS UNINTERESTING. Each rule below is stated as the code implements it. In the
...                       reader, a row that matches several of C to G is counted under the first one, in the order
...                       build_plan checks them (C, D, E, F, G).
...
...                       A. In the capture (cdp_capture.build_serializer, function visible): an element whose computed
...                       display is none is not written, nor anything inside it; one whose visibility is hidden is not
...                       written either, except an input. The tags SCRIPT, STYLE, NOSCRIPT, LINK, META and CANVAS are never
...                       written, and an svg is written empty. Each dropped subtree is counted in stats.hiddenSkipped and
...                       shown as "N hidden subtrees never captured".
...
...                       B. In the parser (dom_config.DomConfiguration._is_noise, with the lists in
...                       salesforce-lightning.json): a tag is noise, and gives no row, when its name is in noiseTags
...                       (lightning-icon, -badge, -pill, -spinner, -helptext, the lightning-formatted-* family,
...                       -avatar and others), or matches noiseTagPatterns (lightning-primitive-*), or its role is one of
...                       presentation, none, separator, progressbar, status, log, alert, tooltip, or its class contains
...                       slds-assistive-text, slds-hide, slds-is-collapsed, forceRecordCoverPhoto, slds-col--padded,
...                       slds-resize-handle, slds-drag-handle or slds-th__action-icon. Elements of the types
...                       picklist_option, internal and structural (skipElementTypes) never become rows.
...
...                       B2. Screen-reader-only text (element_compiler._strip_assistive_text): for the visible label, any
...                       subtree whose class contains an assistiveTextClassFragments entry (slds-assistive-text, sr-only,
...                       visually-hidden, slds-hidden, tooltip-invisible, slds-indicator_unsaved) is removed. The control
...                       is NOT dropped. Such text is the last label source (labelPrecedence ends with assistive_text),
...                       used only when nothing visible names the control; the row then has label_source assistive_text
...                       and Gz Read Page shows "(screen-reader text)" after the label.
...
...                       C. Wrapper (garzai_page_reader.wrapper_twins): an output_field row whose element contains an
...                       editable row's element is a layout wrapper of that field, not a second control. Cut as "layout
...                       wrapper of an editable field".
...
...                       D. Behind a modal (modal_scope, using pom.scope.find_dialog_subtree): when an element matching
...                       [aria-modal=true], div.slds-modal or section.slds-modal is open, rows outside it are cut as
...                       "behind the open modal", and the plan tells the reader to run UseModal On first. A dialog that is
...                       not modal leaves the page listed.
...
...                       E. Chrome (review_table.region_of, applied in build_plan unless include_chrome is true): the
...                       template's chromeContainers decide first, by the NEAREST ancestor carrying a chrome class
...                       fragment (oneConsoleTabset, navexConsoleTabset, slds-context-bar, appNavItems, oneUtilityBar,
...                       forceToastManager, oneAppNavContainer, slds-global-header, nux-coachmark, oneHelpMenu and
...                       others) or chrome tag prefix (one-appnav, one-app-nav-bar, one-app-launcher, oneheader,
...                       one-global, forcesearch, one-utility, navexconsole), against the same for page content
...                       (flexipagePage, forceHighlightsPanel, slds-card, forceRecordLayout and others; flexipage,
...                       forcegenerated-, records-, force-record, runtime_industries, runtime_omnistudio, vlocity); the
...                       nearer wins. With no verdict from those lists: an ancestor tag containing flexipage or starting
...                       with forcegenerated-, c-, runtime_, records-, force-record means page; an ancestor tag starting
...                       with one-appnav, one-app-nav-bar, one-app-launcher, oneheader, one-global, forcesearch,
...                       one-utility or devops_center-panel, or an ancestor header or nav element, means chrome; anything
...                       else is page.
...
...                       F. Table cells (build_plan, TABLE_FAMILIES = table_cell, column_header, datatable, native_table):
...                       cut. The links and checkboxes inside a table are separate rows and are listed.
...
...                       G. No call (build_plan): the reader could not form a call. stock_kw finds no keyword for the
...                       family, or the control has no visible label and no relative xpath that is unique in the capture.
...                       Gz Show with the control's label says why.
...
...                       5. PAGES. render_page prints at most PAGE_SIZE = 20 controls per page, so one answer is at most 24
...                       lines: 2 header lines, the controls, a "not listed" line counting every cut by reason, and a last
...                       line that says "page 1 of N -- NEXT: Gz Read Page page=2" or "END". The last line carries an
...                       8-hex ref (page_ref) so a reader that quotes it has read to the end. The whole plan, every cut
...                       with its reason, is also written to the Robot output folder as gz-page-plan-*.json.
...
...                       6. WHAT THE AI RECEIVES. The text of those pages, printed to the console and returned. Nothing
...                       else. Measured with Gz Walk Plan Size on this page in a CRT build (build 6195632, 2026-10-07): the
...                       capture was 93.3 KB, the parser found 85 elements, 38 were listed, and the AI was given 46 lines /
...                       4,556 bytes in two pages. This suite prints its own numbers for the same page.
...
...                       THE THREE KEYWORDS (contracts, from their signatures in garzai_page_reader.py)
...
...                       Gz Read Page, page=1, include_chrome=False, org=None. Captures the open page, builds the plan,
...                       prints page number page and returns the printed text. include_chrome is true for true, 1, yes or
...                       on (any case). org names the org alias for the store lookup; left empty, it is found from the
...                       page's host in the shipped store, if there is one. A page number past the last prints a
...                       COULD-NOT-CHECK line saying how many pages exist. With no browser or no parser bundle it prints
...                       COULD-NOT-CHECK and fails the step. It never acts on the page.
...
...                       Gz Show, label, index=None. Prints every control with that exact label, listed or cut, in full: each
...                       rung (keyword, ClickItem, relative xpath) with where it came from, the store's rungs with their
...                       verdicts, the member number on a repeated label, the anchor candidates. Up to 3 members are printed
...                       in full; more print one line each and ask for index. No such label: COULD-NOT-CHECK with the
...                       closest labels, and the step fails. It never acts on the page.
...
...                       Gz Verify, label, expected_value, index=None, on_mismatch=fail. Reads the control's value back
...                       without touching it (GetInputValue; VerifyCheckboxValue on or off for a checkbox; GetSelected for a
...                       native select; GetFieldValue for a read-only value; a fresh capture for a Lightning picklist) and
...                       prints a verdict on its last line, compared by meaning (confirm.lenient_equal: 25000 equals
...                       25,000.00, 10/08/2026 equals 10/8/2026). A label that matches several controls needs index.
...
...                       THE VERDICTS Gz Verify can print, as judge() decides them. VERIFIED-PASS: the read-back equals the
...                       expected value, exactly or by meaning (a checkbox: it is on or off as expected). CAUGHT-BUG: it
...                       does not; also when the read returns the field's own label, when a placeholder value such as asdf
...                       landed, and when the read ends with the expected value (typed onto an old value that was never
...                       cleared). COULD-NOT-CHECK: the read was blank, raised, found no such control, or the label
...                       matches several controls and no index was given; never counted as a pass. Only VERIFIED-PASS passes
...                       the step. CAUGHT-BUG and COULD-NOT-CHECK fail it, unless on_mismatch=warn, which prints the
...                       verdict and lets the run continue. A fourth class used elsewhere in this project, PASS-GUARDED
...                       (the org rejected an invalid input as designed), is not produced by any keyword here.
...
...                       Gz Show and Gz Verify reuse the plan of the last Gz Read Page (its org and its include_chrome) for as
...                       long as the page fingerprint (compose_live._fingerprint) and URL are unchanged, and capture afresh
...                       when they change.
Resource                  ../resources/common.robot
Resource                  ../resources/page_reader_steps.robot
Library                   ../resources/garzai_parser_walkthrough.py
Suite Setup               Setup Browser
Suite Teardown            End suite


*** Test Cases ***
1 What the page is to the parser
    [Documentation]       Walks the pipeline's first stages on the live page and prints each stage's numbers: the page as the
    ...                   parser receives it (bytes, shadow roots opened, hidden subtrees dropped), what the parser found
    ...                   (elements, how many are the Salesforce chrome and how many the page's own, by family), the call it
    ...                   proposes for the first ten with its backup, and the text the AI gets, measured in lines and bytes.
    ...                   The last line of the case is the whole story in one line: page KB, parser elements, controls
    ...                   listed, plan lines and bytes. Reads the page only: no click, no typing, no save. Run this case first
    ...                   in a CRT build: Gz Walk Capture installs the parser's one outside dependency (lxml) for the run if
    ...                   the build container lacks it, and says so on the console.
    # PROVEN: the same keywords in the same order passed in a CRT build (build 6195632, 2026-10-07) of the suite this one is
    #         taken from: page 93.3 KB -> 85 elements -> 38 controls -> 46 lines / 4,556 bytes for the AI. An earlier build
    #         (6195617) of that suite failed with "No module named 'lxml'" before the install step existed.
    # NOT-YET-RUN: this file in this repository. It differs from the proven suite in packaging: the page-reading loop is the
    #         keyword Read Every Page Of The Plan And Measure It, the libraries are imported by relative path, and no
    #         page-object store is shipped (the proven build had one, so the byte count printed here may differ a little).
    Open The Zoo Nightmare Inputs Page
    Gz Walk Capture
    Gz Walk Parse
    Gz Walk Calls
    Read Every Page Of The Plan And Measure It
    Gz Walk Summary

2 What the AI is given
    [Documentation]       The keyword the Test Agent calls. Gz Read Page prints page 1 of the plan: 20 controls, each as a
    ...                   person sees it, its family in brackets and the exact call to use, then a line counting what was left
    ...                   out and why, then a last line that says NEXT or END. Gz Read Page page=2 prints the rest. Then
    ...                   Gz Read Page include_chrome=True reads the same page again with the Salesforce header and navigation
    ...                   put back, so you can see exactly what the default strips: compare the first lines of the two
    ...                   answers and the "not listed" line, whose chrome count disappears. Gz Show and Gz Verify keep the
    ...                   include_chrome of the last read, which is why the later cases do not depend on this one.
    # PROVEN: with no page-object store (the situation of this repository), Gz Read Page and Gz Read Page page=2 on this page,
    #         38 controls in 2 pages: page 1 ref abfc39d4, page 2 ref 623598e8, recorded as equal live (the maintainer's CRT
    #         session, 2026-10-06) and offline; and the same two refs reproduced offline on 2026-10-08 by running this
    #         repository's reader and parser bundle over a stored capture of the page. Expect those refs if the page is
    #         unchanged (a ref is a hash of the printed control lines). With the maintainer's store present, 3 of the 38 lines
    #         differ and the refs are 614a5266 and 43af1e14.
    #         include_chrome=True, same offline run: 79 controls in 4 pages, refs c82a4e78, dfd65643, 6c644ff2, 06767757.
    # NOT-YET-RUN: include_chrome=True inside CRT (a build or the editor): only the offline run above exists.
    Open The Zoo Nightmare Inputs Page
    Gz Read Page
    Gz Read Page          page=2
    Gz Read Page          include_chrome=True

3 Search instead of read
    [Documentation]       Three inputs on this page carry the same label, Amount. Gz Show Amount does not read the page, it
    ...                   looks up one label: it prints the three members one after another, each with the call that picks it
    ...                   (the first has none, the others anchor=2 and anchor=3), the relative xpath that names it by the
    ...                   heading above it (List Price, Negotiated Discount, Net to Customer), and a line saying what the
    ...                   page-object store knows about it (here: nothing, this repository ships no store). The last line
    ...                   says how to check one: Gz Verify with index. This is what a search costs the AI: a few lines for
    ...                   the label it asked about, not the whole page.
    # PROVEN: Gz Show Amount in a real browser (headless, nothing saved) on 2026-10-08, with the maintainer's store present:
    #         three members, anchors List Price, Negotiated Discount, Net to Customer. And offline on 2026-10-08, over a stored
    #         capture of the page with this repository and no store: the same three members, their rung-1 calls
    #         TypeText Amount <value>, then the same with anchor=2 and anchor=3.
    # NOT-YET-RUN: Gz Show as a Robot line inside CRT (a build or the editor). The maintainer's editor session of 2026-10-06
    #         sent the agent prompts for Gz Read Page and Gz Verify only.
    Open The Zoo Nightmare Inputs Page
    Gz Show               Amount

4 Act, then verify by meaning
    [Documentation]       Types 25000 into the THIRD Amount field, then checks it. The only action in this suite: the typed
    ...                   value stays on the page, nothing is saved, the browser closes at the end. Gz Verify Amount 25000
    ...                   index=3 reads the field back without touching it and prints VERIFIED-PASS when it reads 25000.
    ...                   The next line expects 99999, which the field does not hold: Gz Verify prints CAUGHT-BUG and,
    ...                   because on_mismatch=warn, the run continues. Without that argument the step would fail, which is
    ...                   what try_keyword needs: it shows the agent PASS or FAIL and nothing else. Amount (3 of 3) loads
    ...                   holding 136,100.00. Whether the build's TypeText replaces that value or appends to it decides what
    ...                   the first Gz Verify prints (see NOT-YET-RUN).
    # PROVEN: Gz Verify Amount 25000 index=3 printed VERIFIED-PASS (reads '25000') after typing into the third Amount, in the
    #         maintainer's CRT editor on 2026-10-06; Gz Verify Amount 99999 index=3 printed CAUGHT-BUG and the step passed under
    #         the warn setting (same session); in a real browser on 2026-10-08 all three lines passed with the maintainer's own
    #         TypeText override, which emptied the 136,100.00 first.
    # NOT-YET-RUN: this case with STOCK TypeText, which is what runs here (no override is imported). Stock TypeText replaced
    #         a pre-filled value 5 times of 5 in a CRT job (2026-10-07); in the editor on 2026-10-06 it
    #         APPENDED on Amount ("148,500.0015000", a CAUGHT-BUG). If your build appends, the first Gz Verify prints
    #         CAUGHT-BUG "typed onto an old value that was never cleared" and the case stops there. That is the verifier doing
    #         its job, and the second Gz Verify line is not reached.
    Open The Zoo Nightmare Inputs Page
    TypeText              Amount                      25000                       anchor=3
    Gz Verify             Amount                      25000                       index=3
    Gz Verify             Amount                      99999                       index=3                     on_mismatch=warn
