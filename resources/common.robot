*** Settings ***
Documentation             The entry resource of this repository, REDUCED to what the page reader needs. It is not a copy of
...                       CRTPagePatterns/resources/common.robot: that file also carries data, recorder and impersonation
...                       keywords this repository leaves out. What is kept is kept unchanged -- the two Library lines
...                       QWeb and QForce, the ${BROWSER} variable, and the executable lines of `Setup Browser` and
...                       `End suite` (their long explanatory comments are shortened). The one line added is the import
...                       of the page reader (CRTPagePatterns' common.robot imports it the same way, so the three
...                       keywords sit in the Test Agent's auto-loaded keyword list).
...
...                       `JwtAuthenticate`, `JwtLogin`, `GetInstanceUrl`, `QueryRecords`, `GoTo`, `TypeText` are keywords
...                       of the licensed QForce library, which CRT provides. Nothing here defines them.
Library                   QWeb
Library                   QForce
# The page reader: Gz Read Page / Gz Show / Gz Verify. Imported by a path relative to this file. Robot imports a
# library while it reads this table, long before a browser exists; the reader touches nothing until a keyword runs.
Library                   garzai_page_reader.py

*** Variables ***
${BROWSER}                chrome


*** Keywords ***
Setup Browser
    # Same line order as CRTPagePatterns' `Setup Browser`. The `options=` flag turns off Chrome's "wants to access
    # other apps and services on this device" prompt; it is kept so the browser starts the way the proven runs did.
    Set Library Search Order                          QForce    QWeb
    Open Browser          about:blank                 ${BROWSER}    options=--disable-features=LocalNetworkAccessChecks
    SetConfig             LineBreak                   ${EMPTY}               #
    Evaluate              random.seed()               random                 # initialize random generator
    SetConfig             DefaultTimeout              5s                    #sometimes salesforce is slow
    # adds a delay of 0.3 between keywords. This is helpful in cloud with limited resources.
    SetConfig             Delay                       0.3


End suite
    Close All Browsers
