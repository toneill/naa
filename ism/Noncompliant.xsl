<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="1.0">
  <xsl:output method="html"/>
  
  
<!-- Some XSLT tranform programs can set parameters on the command line. Things like currentdate could be automated-->  
  
  <xsl:param name="classification" select="'S/HP'"/>
  <xsl:param name="ismversion" select="'201011'"/>
  <xsl:param name="currentdate" select="'20110105'"/>
  <xsl:variable name="SSPLookupDoc" select="document('sample-ssp.xml')/controls"/>
  
<!-- 

About:

This is a XSLT that takes the Australian Government Security Manual (XML format)  as an input, in addition to the SSP XML input
specified in the parameter SSPLookupDoc (above). This generates a HTML document describing all the dispensations, non-compliant,
missing and compliant controls assessed against previous revisions. Missing and expired controls are printed in red, unexpired dispensations 
are in yellow. If a ISM controls has a later revision that the control of the SSP input it is printed in blue indicating a review is required..

Multiple SSP controls can be placed for a single ISM requirement.

The output hides non-compliance to"recommends" level controls.

Using this XML transform:

As an example of use with a XSLT processor:
 java -jar saxon-6.5.5.jar "Australian Government Information Security Manual (ISM).xml"  Noncompliant.xsl > noncompliance.html

 xsltproc Noncompliant.xsl "Australian Government Information Security Manual (ISM).xml" > noncompliance.html
 
 java -jar  xalan2.jar -in "Australian Government Information Security Manual (ISM).xml" -xsl Noncomplaint.xsl  > noncompliance.html

XML Input SSP Document Format:

The format of the SSP XML input is:

<controls>

  <compliant  ....>Why this system is compliant e.g. reference </compliant>
  <dispensation ....>What justification we have put in place to  satisify the accreditation authority for not compling with controls (ISM control #0001)
    <why>
    </why>
    <alternative>
    </alternative>
    <alternative>
    </alternative>
    <risk>
      <initial></initial>
      <effectofalternate>
      </effectofalternate>
      <residuallikelihood>Rare</residuallikelihood>
      <residualconsequence>Minor</residualconsequence>
      <residualrisk>Low</residualrisk>
    </risk>
    <reference></reference>
  </dispensation>
  <notapplicable ....>Why this control/section is not applicable to the system</notapplicable>
  <noncompliant .....>We know we are not compliant and some process should currently be in place to show this</noncompliant>
  
</controls>

Each of the above controls has a number of attributes that show what control(s) it is refering to.
id="{num}" revision="{number}" Indicates that this is a control for the ISM control number and the revision at which it was when the last assessment of the control was done.
section="{section name}" revision="{ismversion}" The whole section can be grouped using this attribute. The revision describes the ISM version so for future releases the applicablility of this section can be re-examined.
chapter="{chapter name}" revision="{ismversion}" The whole chapter can be grouped using this attribute. The revision describes the ISM version so for future releases the applicablility of this section can be re-examined.
expire="yyyymmdd" ato indicate the date at which the control is required to be re-evaluated.

For dispensation there is required to be a expire attribute.

Example:
This is a sample ssp.xml input to the document.


<?xml version="1.0" encoding="UTF-8"?>
<controls>
  <compliant chapter="Australian Government Information Security Manual" revision="201011">As per IT Security Policy</compliant>
  <compliant chapter="Information Security in Government" revision="201011">As per IT Security Policy</compliant>
  <compliant section="The Agency Head" revision="201011">As per IT Security Policy</compliant>
  
  <compliant id="1078" revision="0">Agency policy of telephones is defined in Agency Telephone Policy CEI XXX.YYY</compliant>
  <compliant id="0424" revision="1">Password differences from previous passwords are enforced by the system</compliant>

<dispensation id="1080" revision="0" expire="20151221">
    <why>Encryption of information is not a suitable preservation technique for the long term storage of digital information. The systems that could be put in place to maintain decryption keys for extended priods are likely to break down and prevent access to these important records
    </why>
    <alternative>The limited physical and logical scope of the network
    </alternative>
    <risk>
      <initial>This information needs to be protect</initial>
      <effectofalternate>The limited physical and logical scope of the network
      </effectofalternate>
      <residuallikelihood>Rare</residuallikelihood>
      <residualconsequence>Minor</residualconsequence>
      <residualrisk>Low</residualrisk>
    </risk>
    <reference>see System Security Plan - Dispensation #1</reference>
</dispensation>

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

20110202 Licence Change

20110105 Initial version based of SSP.xsl
             Hide part headings
             chapter and section headings that are expired also get displayed.
             Display Rational where no control exists.
             Display header on dispensation

TODO Features and Bugs:

 * Accept multiple inputs - e.g. a site SSP.xml plus a system specific SSP
                                              , or a no-HGCE to filter out the HGCE controls for systems that don't use them.
 * Extra fields in the input file to present a more general header to the produced document.
 
Licence - BSD-3

Copyright (c) Commonwealth of Australia 2011
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of the Commonwealth of Australia nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

-->
  
  
  <xsl:template match="/">
    <link rel="stylesheet" href="Australian Government Information Security Manual (ISM).css" type="text/css"/>
    <link rel="stylesheet" href="ssp.css" type="text/css"/>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="part">
    <xsl:if test=".//classification=$classification and .//compliance!='recommended'">
      <xsl:apply-templates/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="chapter">
    <xsl:if test=".//classification=$classification and .//compliance!='recommended'">

      <xsl:variable name="title" select="title"/>
      <xsl:variable name="chapterlookup" select="$SSPLookupDoc//*[@chapter=$title]"/>

      <xsl:choose>
          <!-- find overarching control -->
          <xsl:when test="$chapterlookup[@revision &lt; $ismversion] | $chapterlookup[@expire &lt; $currentdate] ">
            <h1><xsl:value-of select="title"/></h1>
             <xsl:apply-templates select="$chapterlookup">
               <xsl:with-param name="revision" select="$ismversion"/>
             </xsl:apply-templates>
          </xsl:when>
          <xsl:when test="$chapterlookup"><!-- current control is in place excempting this chapter -->
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates/>
          </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="section">
    <xsl:if test=".//classification=$classification and .//compliance!='recommended'">
      <xsl:variable name="title" select="title"/>
      <xsl:variable name="sectionlookup" select="$SSPLookupDoc//*[@section=$title]"/>
      <xsl:choose>
          <!-- find overarching control -->
          <xsl:when test="$sectionlookup[@revision &lt; $ismversion] | $sectionlookup[@expire &lt; $currentdate]">
             <h2>
               <xsl:value-of select="title"/>
             </h2>
             <xsl:apply-templates select="$sectionlookup">
               <xsl:with-param name="revision" select="$ismversion"/>
             </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$sectionlookup"><!-- current control is in place excempting this section-->
        </xsl:when>
        <xsl:otherwise>

          <!-- Within controls process it on a block by block basis-->
          <xsl:variable name="rationale" select="rationale"/>
          <xsl:for-each select="controls[.//classification=$classification and .//compliance!='recommended']">
            <xsl:for-each select="block[./classification=$classification and ./compliance!='recommended']">
 
             <xsl:variable name="sectionTitle" select="title"/>
             <xsl:variable name="id" select="ID"/>
             <xsl:variable name="revision" select="revision"/>
             <!--  missing a compliant/notapplicable control or has noncompliant control or dispensation listed or newer revision of control or expired control -->
             <xsl:if test="not( $SSPLookupDoc//compliant[@id=$id] | $SSPLookupDoc//notapplicable[@id=$id] ) or ( $SSPLookupDoc//noncompliant[@id=$id] | $SSPLookupDoc//dispensation[@id=$id] | $SSPLookupDoc//*[@id=$id and ( @revision &lt; $revision )] |$SSPLookupDoc//*[@id=$id and (@expire &lt; $currentdate) ] )">
             <h3>
               <xsl:value-of select="title"/>
            </h3>
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
             <xsl:variable name="controllookup" select="$SSPLookupDoc//noncompliant[@id=$id] | $SSPLookupDoc//dispensation[@id=$id] | $SSPLookupDoc//*[@id=$id and ( @revision &lt; $revision )] |$SSPLookupDoc//*[@id=$id and (@expire &lt; $currentdate) ]"/>
             <xsl:choose>
               <!-- find control(s) -->
               <xsl:when test="$SSPLookupDoc//dispensation[@id=$id] | $SSPLookupDoc//noncompliant[@id=$id]">
                  <!-- display the rational if there is a dispenstation -->
                 <p class="rational">Rational:</p>
                 <xsl:apply-templates select="$rationale/block[title=$sectionTitle]/content"/>
                 <xsl:apply-templates select="$controllookup">
                  <xsl:with-param name="revision" select="$revision"/>
                 </xsl:apply-templates>
               </xsl:when>
               <xsl:when test="$controllookup">
                 <xsl:apply-templates select="$controllookup">
                  <xsl:with-param name="revision" select="$revision"/>
                 </xsl:apply-templates>
               </xsl:when>
               <xsl:otherwise>
                 <p class="rational">Rational:</p>
                 <xsl:apply-templates select="$rationale/block[title=$sectionTitle]/content"/>
                <p class="noncompliant">Non compliant: Missing control<br/></p>
                </xsl:otherwise>
               </xsl:choose>
             </xsl:if>


             </xsl:for-each>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
<!-- Types in the SSP.xml input file-->

<xsl:template match="compliant">
  <xsl:param name="revision"/>
  <xsl:choose>
    <xsl:when test="@expire &lt; $currentdate">
      <p class="noncompliant">Non-compliant - Expired: <xsl:value-of select="@expire"/></p>
      <xsl:if test="@revision &lt; $revision">
       <p class="noncompliant">Assessed against revision <xsl:value-of select="@revision"/> - required review</p><br/>
      </xsl:if>
     <p class="noncompliant">Compliant: <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:when test="@revision &lt; $revision">
      <p class="review">Compliant(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
  </xsl:choose>
</xsl:template>



<xsl:template match="notapplicable">
  <xsl:param name="revision"/>
  <xsl:choose>
    <xsl:when test="@expire &lt; $currentdate">
      <p class="noncompliant">Non-compliant - Expired: <xsl:value-of select="@expire"/></p>
      <xsl:if test="@revision &lt; $revision">
       <p class="noncompliant">Assessed against revision <xsl:value-of select="@revision"/> - required review</p><br/>
      </xsl:if>
     <p class="noncompliant">Not Applicable: <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:when test="@revision &lt; $revision">
      <p class="oldcompliant">Not Applicable(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
  </xsl:choose>
</xsl:template>


<xsl:template match="noncompliant">
  <xsl:param name="revision"/>
  <xsl:choose>
    <!-- expired noncompliant is compliant(????) -->
    <xsl:when test="@expire &lt; $currentdate">
      <p class="compliant">Non-compliant - Expired: <xsl:value-of select="@expire"/></p>
      <xsl:if test="@revision &lt; $revision">
       <p class="compliant">Assessed against revision <xsl:value-of select="@revision"/> - required review</p><br/>
      </xsl:if>
     <p class="compliant">Not Compliant: <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:when test="@revision &lt; $revision">
      <p class="noncompliant">Not Compliant(rev:<xsl:value-of select="@revision"/>): <xsl:value-of select="."/><br/></p>
    </xsl:when>
    <xsl:otherwise>
      <p class="noncompliant">Not Compliant: <xsl:value-of select="."/><br/></p>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>



<xsl:template match="dispensation">
  <xsl:param name="revision"/>
  <h4>Dispensation:</h4>
  <xsl:choose>
    <xsl:when test="@expire &lt; $currentdate">
      <p class="noncompliant">Non-compliant - Expired: <xsl:value-of select="@expire"/></p>
      <xsl:if test="@revision &lt; $revision">
       <p class="noncompliant">Assessed against revision <xsl:value-of select="@revision"/> - required review</p><br/>
      </xsl:if>
      <table>
      <xsl:apply-templates/>
      </table>
      <br/>
    </xsl:when>
    <xsl:when test="@revision &lt; $revision">
      <p class="review">Non-compliant</p>
      <p class="review">Expires: <xsl:value-of select="@expire"/></p>
      <p class="review">Assessed against revision <xsl:value-of select="@revision"/> - required review</p><br/>
      <table>
      <xsl:apply-templates/>
      </table>
      <br/>
    </xsl:when>
    <xsl:otherwise>
      <p class="dispensation">Non-compliant - Expires: <xsl:value-of select="@expire"/></p>
      <table>
      <xsl:apply-templates/>
      </table>
      <br/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="why">
<tr><td>Reasons</td><td colspan="5"><xsl:value-of select="."/></td></tr>
</xsl:template>

<xsl:template match="alternative">
<tr><td>Alternative Risk Mitigation</td><td colspan="5"><xsl:value-of select="."/></td></tr>
</xsl:template>

<xsl:template match="risk">
<tr><td>Initial Risk</td><td colspan="5"><xsl:value-of select="initial"/></td></tr>
<tr><td>Effect of Alternate Mitigation</td><td colspan="5"><xsl:value-of select="effectofalternate"/></td></tr>
<tr><td>Residual likelihood</td><td><xsl:value-of select="residuallikelihood"/></td>
<td>Residual Consequence</td><td><xsl:value-of select="residualconsequence"/></td>
<td>Residual Risk</td><td><xsl:value-of select="residualrisk"/></td></tr>
</xsl:template>

<xsl:template match="reference">
<p class="p1"><xsl:value-of select="."/><br/></p>
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
