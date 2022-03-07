*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    robot_order
    Open Available Browser    ${secret}[url]

Get orders
    ${url}=    Get Value From User    Orders File URL
    Download    ${url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv
    [Return]    ${orders}

Close the annoying modal
    ${locator}=    Set Variable    xpath://*[@class="modal-body"]/div[1]/button[1]
    Wait And Click Button    ${locator}

Fill the form
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order
    Click Button    id:order
    Page Should Contain Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_receipt_pdf}=    Set Variable    ${OUTPUT_DIR}${/}temp${/}order_receipt_${order_number}.pdf
    Wait Until Element Is Visible    id:receipt
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${order_receipt_pdf}
    [Return]    ${order_receipt_pdf}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${order_receipt_png}=    Set Variable    ${OUTPUT_DIR}${/}temp${/}order_receipt_${order_number}.png
    Screenshot    id:robot-preview-image    ${order_receipt_png}
    [Return]    ${order_receipt_png}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close All Pdfs

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}temp    ${zip_file_name}    include=*.pdf
