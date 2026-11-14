*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}    tacticalrmm.example.org
${ADMIN_USER}    admin
${ADMIN_PASSWORD}    Nethesis,1234
${module_id}    ${EMPTY}

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Get HTTP status
    [Arguments]    ${name}    ${url}    @{curl_args}
    ${args} =    Catenate    @{curl_args}
    ${status} =    Execute Command    curl -k -s -o /dev/null -w '\%{http_code}' --resolve ${name}:443:127.0.0.1 ${args} ${url}
    RETURN    ${status}

Web UI answers
    # 2xx, 3xx, 401 and 403 mean the app answers. 000 (no answer), 404 (no
    # Traefik route), 5xx (the frontend is still waiting for tactical-init)
    # and anything else fail.
    ${status} =    Get HTTP status    ${HOST}    https://${HOST}/
    Should Match Regexp    ${status}    ^(2..|3..|401|403)$    The web UI answered HTTP ${status}

API answers
    # Wrong credentials: Django answers 400. A 502 means uwsgi is down.
    ${status} =    Get HTTP status    api.${HOST}    https://api.${HOST}/v2/checkcreds/
    ...    -H 'Content-Type: application/json'    -d '{"username":"nobody","password":"invalid"}'
    Should Match Regexp    ${status}    ^(400|401|403)$    The API answered HTTP ${status}

*** Test Cases ***
Check if tacticalrmm is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

Take screenshots
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Close Browser

Check if tacticalrmm can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host":"${HOST}","http2https":true,"lets_encrypt":false,"TACTICAL_USER":"admin","TACTICAL_PASSWORD":"Nethesis,1234"}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if tacticalrmm configuration reads back
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Evaluate    json.loads($output)    modules=json
    Should Be Equal    ${config.host}    ${HOST}
    Should Be Equal    ${config.API_HOST}    api.${HOST}
    Should Be Equal    ${config.MESH_HOST}    mesh.${HOST}

Check if tacticalrmm works as expected
    Wait Until Keyword Succeeds    15 min    10 sec    Web UI answers

Check if the tacticalrmm API works as expected
    Wait Until Keyword Succeeds    5 min    10 sec    API answers

Check if tacticalrmm is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
