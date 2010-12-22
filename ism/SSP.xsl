<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="2.0">
  <xsl:output method="html"/>
  
  
<!-- Some XSLT tranform programs can set parameters on the command line. Things like currentdate could be automated-->  
  
  <xsl:param name="classification" select="'S/HP'"/>
  <xsl:param name="ismversion" select="'201011'"/>
  <xsl:param name="currentdate" select="'20101221'"/>
  <xsl:variable name="SSPLookupDoc" select="document('Digipres.xml')/controls"/>
  
<!-- 

About:

This is a XSLT that takes the Australian Government Security Manual (XML format)  as an input, in addition to the SSP XML input
specified in the parameter SSPLookupDoc (above). This generates a HTML document describing the state of compliance. It selects all 
the controls of the classification level provided above and searchs the SSPLookupDoc for all the controls. Where there is no control 
there is a "Non-compliant - missing control" in the output in the noncompliant paragraph class (see ssp.css - red by default). 
Compliant controls are in .green, controls that were written against a previous wording of the control are in blue and dispensation 
(previously called waivers and risk assessments) are in yellow.

The output hides "recommends" level controls unless these is a specific control in the SSP XML document.

Using this XML transform:

As an example of use with a XSLT processor:
 java -jar saxon-6.5.5.jar "Australian Government Information Security Manual (ISM).xml"  SSP.xsl > compliance.html

 xsltproc SSP.xsl "Australian Government Information Security Manual (ISM).xml" > compliance.html
 
 java -jar  xalan2.jar -in "Australian Government Information Security Manual (ISM).xml" -xsl SSP.xsl  > compliance.html


XML Input SSP Document Format:

The format of the SSP XML input is:

<controls>

  <compliant  ....>Why this system is compliant e.g. reference </compliant>
  <riskassessed ....>What justfication we have put in place to satisify the accreditation authority for not compling with "should"/"should not" controls (ISM control #1061)</riskassessed>
  <dispensation ....>What justification we have put in place to  satisify the accreditation authority for not compling with "must"/"must not" controls (ISM control #0001)</dispensation>
  <notapplicable ....>Why this control/section is not applicable to the system</notapplicable>
  <noncompliant .....>We know we are not compliant and some process should currently be in place to show this</noncompliant>
  
</controls>

Each of the above controls has a number of attributes that show what control(s) it is refering to.
id="{num}" revision="{number}" Indicates that this is a control for the ISM control number and the revision at which it was when the last assessment of the control was done.
section="{section name}" revision="{ismversion}" The whole section can be grouped using this attribute. The revision describes the ISM version so for future releases the applicablility of this section can be re-examined.
chapter="{chapter name}" revision="{ismversion}" The whole chapter can be grouped using this attribute. The revision describes the ISM version so for future releases the applicablility of this section can be re-examined.

For riskassessed/dispensation there is required to be a expire="yyyymmdd" to indicate the date at which the control is required to be re-evaluated.


Example:
This is a sample ssp.xml input to the document.

<?xml version="1.0" encoding="UTF-8"?>
<controls>
  <compliant chapter="Australian Government Information Security Manual" revision="201011">As per IT Security Policy</compliant>
  <compliant chapter="Information Security in Government" revision="201011">As per IT Security Policy</compliant>
  <compliant section="The Agency Head" revision="201011">As per IT Security Policy</compliant>
  
  <compliant id="1078" revision="0">Agency policy of telephones is defined in Agency Telephone Policy CEI XXX.YYY</compliant>
  <compliant id="0424" revision="1">Password differences from previous passwords are enforced by the system</compliant>
  <riskassessed id="0853" revision="0" expire="20151221">Loading of data can be a very long process and as such automated logout and shutdown is not approprate. Screenlocks are sufficient</riskassessed>
  <dispensation id="1080" revision="0" expire="20151221">Long term archiving cannot use encryption as a reliable preservation technique.</dispensation>

  <notapplicable section="Using the Internet" revision="201011">The system doesn't have internet access</notapplicable>
  <notapplicable id="1110" revision="0">not a Top Secret area</notapplicable>
  <notapplicable id="1113" revision="0">not a Top Secret Area</notapplicable>
  <notapplicable id="0283" revision="2">no HGCE used</notapplicable>

 <compliant section="Media Destruction" revision="201011">System Standard Operating Procedures (ref) refer to ISM for mechanisms.</compliant>
 <compliant section="Media Disposal" revision="201011">System Standard Operating Procedures (ref) refer to ISM for mechanisms.</compliant>
 <notapplicable section="Web Applications">no web applications</notapplicable>
 <notapplicable section="Web Application Development" revision="201011">no web applications</notapplicable >

 <notapplicable section="Secure Multipurpose Internet Mail Extension" revision="201011">no S/MIME</notapplicable>
 <notapplicable section="OpenPGP Message Format" revision="201011">no PGP</notapplicable>
 <notapplicable section="Internet Protocol Security" revision="201011">no IPSec</notapplicable>
 <notapplicable section="Virtual Local Area Networks" revision="201011">no VLANs</notapplicable>
 <notapplicable section="Wireless Local Area Networks" revision="201011">No wireless on system</notapplicable>
 <notapplicable section="Internet Protocol Telephony" revision="201011">No wireless on system</notapplicable>
 <notapplicable section="Peripheral Switches" revision="201011">no KVM switches</notapplicable>
 <notapplicable chapter="Gateway Security" revision="201011">no cross domain</notapplicable>
 <notapplicable chapter="Working Off-Site" revision="201011">no working offsite</notapplicable>

</controls>

Version History:

20101221 Current version based of the XML schema release December 2010


TODO Features and Bugs:

 * Accept multiple inputs - e.g. a site SSP.xml plus a system specific SSP
                                              , or a no-HGCE to filter out the HGCE controls for systems that don't use them.
 * Extra fields in the input file to present a more general header to the produced document.
 * Enforce riskassesed for "should"/"should not" and dispensation for "must"/"must not"
 * No current support for breaks of "requires" controls (ISM control #1060 )
 * Not sure the logic around recommends level controls


Copyright - Commonwealth of Australia 2010
Licence - Creative Commons Attribution version 3 as per current AGIMO guidance

-->
  
  
  <xsl:template match="/">
    <link rel="stylesheet" href="Australian Government Information Security Manual (ISM).css" type="text/css"/>
    <link rel="stylesheet" href="ssp.css" type="text/css"/>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="part">
    <xsl:if test=".//classification=$classification and .//compliance!='recommended'">
    
      <h1>
        <xsl:value-of select="title"/>
      </h1>
      <xsl:apply-templates/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="chapter">
    <xsl:if test=".//classification=$classification and .//compliance!='recommended'">
      <h2>
        <xsl:value-of select="title"/>
      </h2>
      <xsl:variable name="title" select="title"/>
      <xsl:variable name="chapterlookup" select="$SSPLookupDoc//*[@chapter=$title]"/>

      <xsl:choose>
          <!-- find overarching control -->
          <xsl:when test="$chapterlookup">
          
             <xsl:apply-templates select="$chapterlookup">
               <xsl:with-param name="revision" select="$ismversion"/>
             </xsl:apply-templates>
          
          </xsl:when>
          <xsl:otherwise>
           <xsl:apply-templates/>
          </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="section">
    <xsl:if test=".//classification=$classification and .//compliance!='recommended'">
      <h3>
        <xsl:value-of select="title"/>
      </h3>
      <xsl:variable name="title" select="title"/>
      <xsl:variable name="sectionlookup" select="$SSPLookupDoc//*[@section=$title]"/>
      <xsl:choose>
          <!-- find overarching control -->
          <xsl:when test="$sectionlookup">
             <xsl:apply-templates select="$sectionlookup">
               <xsl:with-param name="revision" select="$ismversion"/>
             </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>

          <!-- Within controls process it on a block by block basis-->
          <xsl:for-each select="controls[.//classification=$classification and .//compliance!='recommended']">
            <xsl:apply-templates/>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="block">
    <xsl:variable name="id" select="ID"/>
    <xsl:if test="classification=$classification and (compliance!='recommended' or $SSPLookupDoc//*[@id=$id])">
    <h5>
      <xsl:value-of select="title"/>
    </h5>
    <p class="p2">
      <xsl:text>Control: </xsl:text>
      <xsl:value-of select="ID"/>
      <xsl:text>; Revision: </xsl:text>
      <xsl:value-of select="revision"/>
      <xsl:text>; Updated: </xsl:text>
      <xsl:value-of select="updated"/>
      <xsl:text>; Applicability: </xsl:text>
      <xsl:for-each select="classification">
        <xsl:value-of select="."/>
        <xsl:choose>
          <xsl:when test="position()!=last()">
            <xsl:text>, </xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
      <xsl:text>; Compliance: </xsl:text>
      <xsl:value-of select="compliance"/>
    </p>
    <!-- Display the content of the block -->
    <xsl:apply-templates select="content"/>
    
    <!-- Display the controls  -->
    <xsl:variable name="revision" select="revision"/>
    <xsl:variable name="controllookup" select="$SSPLookupDoc//*[@id=$id]"/>
    <xsl:choose>
      <!-- find control(s) -->
      <xsl:when test="$controllookup">
        <xsl:apply-templates select="$controllookup">
         <xsl:with-param name="revision" select="$revision"/>
         </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
     <p class="noncompliant">Non compliant: Missing control<br/></p>
    </xsl:otherwise>
    </xsl:choose>
    </xsl:if>
  </xsl:template>

<xsl:template match="compliant">
  <xsl:param name="revision"/>
  <xsl:choose>
    <xsl:when test="@revision &lt; $revision">
      <p class="review">Compliant(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:otherwise>
      <p class="compliant">Compliant: <xsl:value-of select="."/><br/></p>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="riskassessed">
<!-- this is for "should" / "should not" controls -->
  <xsl:param name="revision"/>
  <xsl:param name="expire"/>
  <xsl:choose>
    <xsl:when test="@expire &lt; $currentdate">
      <p class="noncompliant">Non-compliant: Expired (<xsl:value-of select="@expire"/>): Previously accepted(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:when test="@revision &lt; $revision">
      <p class="review">Non-compliant: Expires (<xsl:value-of select="@expire"/>): Risk Accepted(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:otherwise>
      <p class="dispensation">Non-compliant: Expires (<xsl:value-of select="@expire"/>): Risk Accepted: <xsl:value-of select="."/><br/></p>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="dispensation">
<!-- this is for "must" / "must not" controls -->
  <xsl:param name="revision"/>
  <xsl:param name="expire"/>
  <xsl:choose>
    <xsl:when test="@expire &lt; $currentdate">
      <p class="noncompliant">Manditory control - non-compliant: Expired (<xsl:value-of select="@expire"/>): Previously accepted(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:when test="@revision &lt; $revision">
      <p class="review">Manditory control - non-compliant: Expires (<xsl:value-of select="@expire"/>): Risk Accepted(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:otherwise>
      <p class="dispensation">Manditory control - non-compliant: Expires (<xsl:value-of select="@expire"/>): Risk Accepted: <xsl:value-of select="."/><br/></p>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="notapplicable">
  <xsl:param name="revision"/>
  <xsl:choose>
    <xsl:when test="@revision &lt; $revision">
      <p class="oldcompliant">Not Applicable(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:otherwise>
      <p class="compliant">Not Applicable: <xsl:value-of select="."/><br/></p>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="noncompliant">
  <xsl:param name="revision"/>
  <xsl:choose>
    <xsl:when test="@revision &lt; $revision">
      <p class="noncompliant">Not Compliant(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:otherwise>
      <p class="noncompliant">Not Compliant: <xsl:value-of select="."/><br/></p>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- these are here to prevent duplicate output -->
  <xsl:template match="title"/>
  <xsl:template match="ID"/>
  <xsl:template match="classification"/>
  <xsl:template match="revision"/>
  <xsl:template match="updated"/>
  <xsl:template match="compliance"/>
  
  
  <!-- Content based templates - copied from original ISM XSLT -->
  <xsl:template match="para">
    <p class="p1"><xsl:value-of select="."/><br/> </p>
  </xsl:template>
  <xsl:template match="list">
    <p class="p1">
      <xsl:value-of select="head"/>
    </p>
    <ul class="l1">
      <xsl:for-each select="*">
        <xsl:choose>
          <xsl:when test="name()='item'">
            <li>
              <xsl:value-of select="."/>
            </li>
          </xsl:when>
          <xsl:when test="name()='list'">
            <li>
              <xsl:value-of select="head"/>
            </li>
            <ul class="l2">
              <xsl:for-each select="item">
                <li>
                  <xsl:value-of select="."/>
                </li>
              </xsl:for-each>
            </ul>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
    </ul>
    <p class="p1"> </p>
  </xsl:template>
  
  <xsl:template match="table">
    <table align="center">
      <xsl:for-each select="header">
        <tr>
          <xsl:for-each select="cell">
            <th align="center" colspan="{@colspan}" rowspan="{@rowspan}">
              <p class="p1">
                <xsl:value-of select="."/>
              </p>
            </th>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
      <xsl:for-each select="row">
        <tr>
          <xsl:for-each select="cell">
            <td align="left" colspan="{@colspan}" rowspan="{@rowspan}">
              <p class="p1">
                <xsl:value-of select="."/>
              </p>
            </td>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
    </table>
    <p class="p1"> </p>
  </xsl:template>
  
  <xsl:template match="image">
    <p class="p3"><img src="data:image/jpeg;base64,{.}"/><br/> </p>
  </xsl:template>
</xsl:stylesheet>
