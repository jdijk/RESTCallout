<h1>REST Callout</h1>

<p>
A framework to make it easier (read less coding) to make REST calls from Salesforce. Currently it supports the following
use cases:
</p>
<ol>
<li>Input data is taken from a Salesforce Object, REST call is made, result is stored in Salesforce Object</li>
<li>A list of results is retrieved as REST call and shown using an External Object.</li>
</ol>

<h2>Setup</h2>
<p>
In order to add the framework to your Salesforce org follow the following steps.
</p>
<h3>1. Setup global picklist values</h3>
<p>
I'm using the current Eclipse plugin to access my Salesforce objects and deploy them to Git. However the current version does not support global value sets yet. This will, for sure, be solved in a later version but in the meantime this means you've to follow some manual steps to set this up.
</p>
<p> 
In your Salesforce org you've to setup two Picklist Value Sets before importing the rest of the object. In you Setup go to 'Picklist Value Sets'. Now create two value sets. First create one with the name 'Integration Conversion Types' and give it the following values:
</p>
<ul>
<li>Julian Date</li>
<li>DD/MM/YYYY</li>
<li>MM/DD/YYYY</li>
<li>Y/N</li>
<li>True/False</li>
<li>Custom</li>
</ul>
<p>
Next create a second Picklist Value Set named 'Integration Field Type' and give it the following values:
</p>
<ul>
<li>Text</li>
<li>Number</li>
<li>Date</li>
<li>Boolean</li>
</ul>

<h3>2. Deploy the repository to your org</h3>

<p>Next you can deploy the contents of this repository to your org by pressing the next button.</p>

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

<h3>3. Assing Permission Set to relevant user</h3>

<p>Assign the 'REST Integration Framework' permission set to a relevant user in your org.</p>

<h2>Desclaimer</h2>

<p>
Copyright (c) 2017, Jack van Dijk, Sales Engineering, Salesforce.com Inc.<br />
All rights reserved.
</p>
<p>
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
<ul>
<li>Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.</li>
<li>Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.</li>
<li>Neither the name of the salesforce.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.</li>
</ul>
</p>
<p>
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
</p>
