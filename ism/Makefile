
all: ISM_Compliance.html ISM_MissingCompliance.html

ISM_Compliance.html: SSP.xsl sample-ssp.xml
	java -jar saxon-6.5.5.jar "Australian Government Information Security Manual (ISM).xml"  SSP.xsl > $@

ISM_MissingCompliance.html: Noncompliant.xsl sample-ssp.xml
	java -jar saxon-6.5.5.jar "Australian Government Information Security Manual (ISM).xml"  Noncompliant.xsl > $@

zip:
	zip "System Information Security Manual (2010) compliance" *
# java -jar  /usr/share/java/saxon-6.5.5.jar Australian\ Information\ Security\ Manual\ \(ISM\).xml SSP.xsl > ISM_Compliance.html
# java -jar  /usr/share/java/xalan2.jar -in Australian\ Information\ Security\ Manual\ \(ISM\).xml -xsl SSP.xsl > ISM_Compliance.html
# xsltproc SSP.xsl "Australian Government Information Security Manual (ISM).xml" > ISM_Compliance.html
