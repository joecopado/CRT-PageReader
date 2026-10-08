*** Settings ***
Documentation             Two plain-sentence keywords for tests/how-the-page-reader-works.robot, so the test cases read as
...                       sentences. WRITTEN FOR THIS REPOSITORY (not copied from CRTPagePatterns); every line in a body
...                       is a line the CRTPagePatterns suites already use, in the same order.
Resource                  common.robot
Resource                  garzai_navigation.robot
Library                   garzai_parser_walkthrough.py
Library                   Collections


*** Keywords ***
Open The Zoo Nightmare Inputs Page
    [Documentation]       Log in to the Salesforce developer org that holds the Zoo Nightmare Inputs tab, with the JWT trio,
    ...                   and put the browser on that tab, then wait until the page has drawn its first labels, so a capture
    ...                   is of the finished page. The three variables are defined by CRT (project or robot variables);
    ...                   their values are not in this repository. Open Nav Tab is in resources/garzai_navigation.robot.
    ${token}=             JwtAuthenticate             ${client_idSlock}           ${usernameSlock}            ${private_keySlock}
    JwtLogin
    Open Nav Tab          Zoo_Nightmare_Inputs
    VerifyText            Renewal Notice (days)       timeout=30


Read Every Page Of The Plan And Measure It
    [Documentation]       Call Gz Read Page for page 1, learn from its last line how many pages there are, read the rest,
    ...                   then let Gz Walk Plan Size count the lines and bytes of exactly the text the AI was given.
    ...                   The loop is the one in CRTPagePatterns' tests/parser-walkthrough.robot, moved here unchanged.
    ${first}=             Gz Read Page
    ${total}=             Gz Walk Pages Total         ${first}
    @{pages}=             Create List                 ${first}
    ${stop}=              Evaluate                    int(${total}) + 1
    FOR    ${p}    IN RANGE    2    ${stop}
        ${text}=          Gz Read Page                page=${p}
        Append To List    ${pages}                    ${text}
    END
    Gz Walk Plan Size     ${pages}
