rem Builds HTML SSP documents from XML

java -jar saxon-6.5.5.jar "Australian Government Information Security Manual (ISM).xml"  SSP.xsl > ISM_Compliance.html"

java -jar saxon-6.5.5.jar "Australian Government Information Security Manual (ISM).xml"  Noncompliance.xsl > ISM_MissingCompliance.html"
