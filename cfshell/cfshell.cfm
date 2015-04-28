<cfsetting enablecfoutputonly="true">
<cfparam name="_cmd" default="">
<cfset _lstAllowedClients = "127.0.0.1">
<cfset _version = "0.3">
<cfset _crlf = chr(13) & chr(10)>
<cfif not structKeyExists(session,"_cfshell_")>
	<cfset session._cfshell_ = structNew()>
</cfif>
<cfif _cmd eq ""><cfexit></cfif>
<cfif not listFind(_lstAllowedClients,cgi.REMOTE_ADDR)>
	<cfheader statuscode="403">
	<cfoutput>Connection refused.</cfoutput>
	<cfexit>
</cfif>

<cftry>
	<cfloop collection="#session._cfshell_#" item="_key">
		<cfset variables[_key] = session._cfshell_[_key]>
	</cfloop>
	<cfswitch expression="#listFirst(_cmd,' ')#">
		<cfcase value=".help">
			<cfoutput>#_command_help()#</cfoutput>
		</cfcase>
		<cfcase value=".call">
			<cfif listLen(_cmd,' ') gt 1>
				<cfoutput>#_command_call(listGetAt(_cmd,2,' '))#</cfoutput>
			<cfelse>
				<cfthrow message="Invalid format. Usage: .call template_path">
			</cfif>
		</cfcase>
		<cfcase value=".new">
			<cfif listLen(_cmd,' ') gte 3>
				<cfset _expr = "<cfset #listGetAt(_cmd,2,' ')# = createObject('component','#listGetAt(_cmd,3,' ')#')>">
				<cfoutput>#_command_run(_expr)#</cfoutput>
			<cfelse>
				<cfthrow message="Invalid format. Usage: .new var_name cfc_path">
			</cfif>
		</cfcase> 
		<cfcase value=".print,##,.##">
			<cfset _expr = "###listRest(_cmd,' ')###">
			<cfoutput>#_command_run(_expr)#</cfoutput>
		</cfcase>
		<cfcase value=".cfscript,.cfs">
			<cfset _expr = "<cfscript>#listRest(_cmd,' ')#</cfscript>">
			<cfoutput>#_command_run(_expr)#</cfoutput>
		</cfcase>
		<cfcase value=".install">
			<cfif listLen(_cmd,' ') gt 2>
				<cfset _command_install(listGetAt(_cmd,2,' '),listGetAt(_cmd,3,' '))>
			<cfelseif listLen(_cmd,' ') gt 1>
				<cfset _command_install(listGetAt(_cmd,2,' '))>
			<cfelse>
				<cfthrow message="Invalid format. Usage: .install app_name [path]">
			</cfif>
			<cfoutput>Done.</cfoutput>
		</cfcase>
		<cfdefaultcase>
			<cfoutput>#_command_run(_cmd)#</cfoutput>
		</cfdefaultcase>
	</cfswitch>
	<cfloop collection="#variables#" item="_key">
		<cfif left(_key,1) neq "_">
			<cfset session._cfshell_[_key] = variables[_key]>
		</cfif>
	</cfloop>

	<cfcatch type="any">
		<cfheader statuscode="500">
		<cfoutput>#htmlEditFormat(cfcatch.message)##_crlf#<cfif cfcatch.detail neq "">#htmlEditFormat(cfcatch.detail)##_crlf#</cfif></cfoutput>
	</cfcatch>	
</cftry>

<cffunction name="_command_run" access="private" returntype="string">
	<cfargument name="expr" type="string" required="true">
	<cfset var rtn = "">
	<cfset var tempFile = GetTempFile("./","cfshell_")>
	<cffile action="write" file="#tempFile#" output="<cfoutput>#arguments.expr#</cfoutput>">
	<cftry>
		<cfset rtn = _command_call(getFileFromPath(tempFile))>
		<cfcatch type="any">
			<cffile action="delete" file="#tempFile#">
			<cfrethrow>	
		</cfcatch>
	</cftry>
	<cffile action="delete" file="#tempFile#">
	<cfreturn rtn>
</cffunction>

<cffunction name="_command_help" access="private" returntype="string">
	<cfset var rtn = "CFShell v#_version# - Interactive shell for CFML" & _crlf
					& "by oscar arevalo - Oct 2009" & _crlf & _crlf
					& "Type CFML statements to evaluate interactively. If the statement" & _crlf
					& "generates any output, it will be displayed." & _crlf & _crlf
					& "Available Commands:" & _crlf
					& " .help : displays this message" & _crlf
					& " .cfscript <staments> : executes the rest of the line as cfscript code" & _crlf
					& " .get <template_path> : does a GET request to the given page (output supressed)" & _crlf
					& " .sget <template_path> : same as .get without supressing output" & _crlf
					& " .post <template_path> <arguments> : does a POST request to the given template (output supressed)" & _crlf
					& " .spost <template_path> <arguments> : same as .post without supressing output" & _crlf
					& " .call <template_path> : does a cfcinclude of the given template" & _crlf
					& " .print <statement> : surrounds with ## and evaluates the rest of the string" & _crlf
					& " .## <statement> : same as .print" & _crlf
					& " .new <var_name> <cfc_path> : shorthand for <var_name> = createObject('component',<cfc_path>)" & _crlf
					& " .install <app_name> [<path>] : downloads and unpacks the given application from RIAForge. If no path is given, unzips to 'downloadedapps' in the local dir" & _crlf
					& " .exit : exits cfshell" & _crlf& _crlf>
	<cfreturn rtn>
</cffunction>

<cffunction name="_command_call" access="private" returntype="string">
	<cfargument name="template" type="string" required="true">
	<cfset var _rtn = "">
	<cfsavecontent variable="_rtn"><cfinclude template="#arguments.template#"></cfsavecontent>
	<cfreturn _rtn>
</cffunction>

<cffunction name="_command_install" access="private" returntype="string">
	<cfargument name="app" type="string" required="true">
	<cfargument name="path" type="string" required="false" default="./downloadedapps">
	<cfset var content = 0>
	<cfset var zippath = getTempFile(getTempDirectory(),"cfshellinstall")>
			
	<cfhttp method="get" 
			url="http://#arguments.app#.riaforge.org/index.cfm?event=action.download&doit=1" 
			getasbinary="auto"
			result="content"
			throwonerror="true"
			redirect="true"
			file="#getFileFromPath(zipPath)#"
			path="#getTempDirectory()#">
	<cfif content.text>
		<cfthrow message="Application not found or download not available directly from RIAForge.org">
	</cfif>
	<cfif not directoryExists(expandPath(arguments.path))>
		<cfdirectory action="create" directory="#expandPath(arguments.path)#" mode="777">
	</cfif>
	<cfzip action="unzip" destination="#expandPath(arguments.path)#" file="#zippath#" overwrite="yes" recurse="true"></cfzip>
	<cffile action="delete" file="#zippath#">
</cffunction>

