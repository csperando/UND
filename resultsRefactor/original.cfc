<cfcomponent extends="controller">
	<cffunction name="records">
		<!--- form parameters --->
		<!--- user input --->
		<cfparam name="location" default=""/>
		<cfparam name="classification" default=""/>

		<!--- hidden values --->
		<cfparam name="city" default=""/>
		<cfparam name="state" default=""/>
		<cfparam name="zip" default=""/>
		<cfparam name="sic" default=""/>
		<cfparam name="description" default=""/>
        <cfparam name="id" default=""/>
		<cfparam name="mailfile_id" default=""/>
        <cfparam name="company" default=""/>

		<!--- top autocomplete suggestions --->
		<cfparam name="topLocation" default=""/>
		<cfparam name="topClassification" default=""/>

		<!--- drill down (dd) filters --->
		<cfparam name="ddCompany" default=""/>
		<cfparam name="ddAreaCode" default=""/>
		<cfparam name="ddZIPCode" default=""/>
		<cfparam name="ddLetter" default=""/>
		<cfparam name="ddSpecialty" default=""/>

		<!--- variables for results --->
		<cfparam name="URL.PMFID" default=""/>

		<!--- vars for result formatting in view --->
		<cfparam name="page" default="1"/>
		<cfparam name="startRow" default="0"/>
		<cfparam name="resultsPerPage" default="20"/>
		<cfset endRow = startRow + resultsPerPage/>

		<!--- location/classification results subtitle content --->
		<cfset displayLocation = location/>
		<cfset displayClassification = classification/>

		<cfset cityUnabbreviated = ""/>

		<!--- Popular classifications (shown on listings error); max. of 5 --->
		<cfset errorPopularCategories = ['Doctors', 'Attorneys', 'Churches', 'Dentists', 'Restaurants']/>

		<!--- Examples for #classification placeholder text --->
		<cfset placeholderExamples = ["CHURCHES", "DENTISTS", "DOCTORS", "HOTELS", "LAWYERS", "MOTELS", "PLUMBERS"]/>
		<cfset placeholder = placeholderExamples[randRange(1, arrayLen(placeholderExamples))]/>

		<!--- alerts for testing --->
		<!--- <cfset testFlag = "testFlag"/> --->

        <cfset pageTitle = 'Search for local ' & description & ' in or near ' & city & ', ' & state & ' | Original YP'/>
        <cfset pageDescription = 'Local ' & description & ' in or near ' & city & ', ' & state & '.'/>
        <cfset pageKeywords = 'yp, yellow pages, legal yp, original yellow pages, original yp network, search, directory services, simple search, local search, regional search, national search, doctor search, attorney search, dentist search, online advertising, yellow page directory, directory, online business directory, free business listing, online business listing, usa, ' & description & ', ' & city & ', ' & state />

		<!---
			Validate user's location input
			Decision tree included in documentation: https://github.com/YPDS/results.cfc/blob/main/location_results.pdf
		--->

		<!--- location only numeric if no autocomplete selection made --->
		<cfif IsNumeric("#location#")>
			<cfquery name="zipQuery" datasource="memory">
				SELECT TOP 1 zip, primary_city, state
				FROM toyp_zipCodes
				WHERE zip = <cfqueryparam value='#location#' />
			</cfquery>

			<cfif zip EQ location>
				<!--- valid zip input, make sure all values defined here --->
				<cfset city = trim(zipQuery.primary_city)/>
				<cfset state = trim(zipQuery.state)/>
				<cfset location = city & ', ' & state/>

			<cfelse>
				<!---
					form zip (from autocomplete) doesn't match user input, use
					zip query to validate user input or topLocation
				--->
				<cfif zipQuery.recordCount EQ 1>
					<!--- user input is valid zip code --->
					<cfset city = trim(zipQuery.primary_city)/>
					<cfset state = trim(zipQuery.state)/>
					<cfset location = city & ', ' & state/>

				<cfelse>
					<!--- invalid numeric input, check for topLocation --->
					<cfif topLocation EQ "">
						<!--- NO VALID INPUT --->
						<cfset state = "FL"/>
						<cfset city = ""/>
						<cfset displayLocation = state/>

					<cfelse>
						<!--- Use top location for results --->


						<cfset state = right(topLocation, 2)/>
						<cfset city = left(topLocation, find(",", topLocation)-1)/>
						<cfset displayLocation = city & ', ' & state/>



					</cfif>
				</cfif>
			</cfif>

		<!--- non-numeric input, check city state or state search --->
		<cfelse>

			<!--- check if state search --->
			<cfif city EQ "@toyp-stateSearch">
				<cfset city = "%"/>
				<cfquery name="stateQuery" datasource="memory">
					SELECT TOP 1 ABBREVIATION, NAME
					FROM toyp_states
					WHERE ABBREVIATION LIKE <cfqueryparam value='#state#%' /> OR NAME LIKE '#state#%'
				</cfquery>

				<!--- <cfset testFlag = location /> --->
				<cfset location = trim(state)/>
				<!--- <cfset location = stateQuery.NAME /> --->
				<cfset displayLocation = stateQuery.NAME/>

			<cfelse>
				<!--- find city state --->
				<cfset comma = find(",", location)/>

				<!--- check for comma --->
				<cfif comma EQ 0>
					<!--- <cfset testFlag = "test"/> --->

					<!--- no comma, invalid input format check for topLocation --->
					<cfif topLocation EQ "">
						<!--- NO VALID INPUT --->
						<cfset state = "FL"/>
						<cfset city = "Orlando"/>

						<!--- WF: Flow with [Classification] in or near [Location] format --->
						<cfset displayLocation = state & ". No results for: " & location/>
					<cfelse>




						<!--- --------------- --->
						<cfset state = left(topLocation, 2)/>
						<!--- --------------- --->



						<!--- <cfset city = left(topLocation, find(",", topLocation)-1)/> --->
						<cfset city = ""/>

						<!--- WF: Flow with [Classification] in or near [Location] format --->
						<cfset displayLocation = city & ', ' & state & ". No results for: " & location/>





					</cfif>

				<cfelse>
					<!--- <cfset testFlag = "test"/> --->

					<!--- comma found, verify 'city' and 'state' --->
					<cfif location EQ city & ', ' & state >
						<!--- Default case when autocomplete suggestion selected. Continue --->
						<!--- <cfset testFlag = "test"/> --->

					<cfelse>
						<!--- user modified text after selection, verify 'new' input --->
						<cfset city = left(location, comma-1)/>
						<cfset state = trim(right(location, len(location)-comma))/>

						<!--- <cfset testFlag = city & ', ' & state /> --->

						<cfquery name="stateQuery" datasource="memory">
							SELECT TOP 1 ABBREVIATION, NAME
							FROM toyp_states
							WHERE ABBREVIATION LIKE <cfqueryparam value='#state#%' /> OR NAME LIKE <cfqueryparam value='#state#%' />
						</cfquery>

						<cfif stateQuery.recordCount EQ 1>
							<!--- state valid, verify city --->
							<cfset state = stateQuery.ABBREVIATION/>

							<cfquery name="cityQuery" datasource="memory">
								SELECT TOP 1 CITY_NAME
								FROM toyp_cityStates
								WHERE STATE = <cfqueryparam value='#state#' /> AND	CITY_NAME = <cfqueryparam value='#city#' />
							</cfquery>

							<cfif cityQuery.recordCount EQ 0>
								<cfquery name="cityQuery" datasource="memory">
									SELECT TOP 1 CITY_NAME
									FROM toyp_cityStates
									WHERE STATE = <cfqueryparam value='#state#' /> AND CITY_NAME LIKE <cfqueryparam value='#city#%' />
								</cfquery>
							</cfif>

							<cfif cityQuery.recordCount EQ 1>
								<!--- valid city input --->
								<cfset city = cityQuery.CITY_NAME/>

							<cfelse>
								<!--- invalid city, use topLocation --->
								<cfif topLocation EQ "">
									<!--- NO VALID INPUT --->
									<cfset state = "FL"/>
									<cfset city = "Orlando"/>
									<cfset displayLocation = state/>
								<cfelse>
									<cfset state = right(topLocation, 2)/>
									<cfset city = left(topLocation, find(",", topLocation)-1)/>
									<cfset displayLocation = city & ', ' & state/>
								</cfif>
							</cfif>

						<cfelse>
							<!--- <cfset testFlag = "test"/> --->

							<!--- invalid state input, use topLocation --->
							<cfif topLocation EQ "">
								<!--- NO VALID INPUT --->
								<cfset state = "FL"/>
								<cfset city = "Orlando"/>
								<cfset displayLocation = "No results for: " & location & ". Displaying results for " & state/>
							<cfelse>
								<cfset state = right(topLocation, 2)/>
								<cfset city = left(topLocation, find(",", topLocation)-1)/>
								<cfset displayLocation = "No results for: " & location & ". Displaying results for " & city & ', ' & state/>
							</cfif>

						</cfif> <!--- end state/city input verification --->
					</cfif> <!--- end input like autocomplete --->
				</cfif> <!--- end if comma --->
			</cfif> <!--- end @stateSearch --->
		</cfif> <!--- end isnumeric if --->

		<!---
			Location is verified.
			WF: Verify abbreviations for location and create cityUnabbreviated if results need to be combined.
		--->
		<cfset abbreviations = [ <!--- [Abbreviation, Unabbreviated] --->
			['Afb', 'Air Force Base'], ['A F B', 'Air Force Base'], ['Bch', 'Beach'], ['Blvd', 'Boulevard'], ['Brk', 'Brook'], ['Cmns', 'Commons'], ['Crk', 'Creek'], ['Cyn ', 'Canyon '], ['Ests', 'Estates'], ['fld', 'field'],
			['Fls', 'Falls'], ['Ft ', 'Fort '], ['Gdns', 'Gardens'], ['Hrbr', 'Harbor'], ['JB', 'Joint Base'], ['Mt', 'Mount'], ['Mtn', 'Mountain'], [' Pk', ' Park'], ['Pt ', 'Port '], ['Rvr', 'River'], ['Spg', 'Spring'],
			['Spgs', 'Springs'], ['Twp', 'Township'], ['Twsp', 'Township'], ['Wht', 'White']
		]/>

		<!--- Update cityUnabbreviated as necessary --->
		<cfloop index="i" from="1" to="#arrayLen(abbreviations)#">
			<cfif city CONTAINS "#abbreviations[i][1]#">
				<cfif cityUnabbreviated EQ "">
					<cfset cityUnabbreviated = replace(city, abbreviations[i][1], abbreviations[i][2])/>
				<cfelse>
					<cfset cityUnabbreviated = replace(cityUnabbreviated, abbreviations[i][1], abbreviations[i][2])/>
				</cfif>
			</cfif>
		</cfloop>


		<!---
			At this point the city and state parameters should be well defined.
			Verify classification input the same way defaulting to topClassification.
		--->

		<!--- escape single quotes for sql --->
		<cfset classForQuery = replace(classification, "'", "''", "all")/>
		<cfquery name="verifyClassification" datasource="memory">
			SELECT TOP 1 SIC_CODE, DESCRIPTION
			FROM SIC_DESCRIPTIONS
			WHERE DESCRIPTION = <cfqueryparam value='#classForQuery#' />
		</cfquery>

		<cfif verifyClassification.recordCount EQ 0>
			<!--- invalid user input, check hidden params --->
			<cfif sic NEQ "" or description NEQ "">
				<cfquery name="verifyClassification" datasource="memory">
					SELECT TOP 1 SIC_CODE, DESCRIPTION
					FROM SIC_DESCRIPTIONS
					WHERE SIC_CODE = <cfqueryparam value='#sic#' /> OR DESCRIPTION = <cfqueryparam value='#description#' />
				</cfquery>

				<cfif verifyClassification.recordCount EQ 0>
					<!--- invalid use topClassification --->
					<cfset description = topClassification/>
					<cfquery name="getSIC" datasource="memory">
						SELECT TOP 1 SIC_CODE
						FROM SIC_DESCRIPTIONS
						WHERE DESCRIPTION = <cfqueryparam value='#description#' />
					</cfquery>
					<cfset sic = getSIC.SIC_CODE/>
					<cfset displayClassification = "No results for '" & classification & "'. Displaying results for '" & description & "'"/>

				<cfelse>
					<!--- success --->
				</cfif>

			<cfelse>
				<!--- no other params defined: use topClassification --->
				<cfset description = topClassification/>
				<cfquery name="getSIC" datasource="memory">
					SELECT TOP 1 SIC_CODE
					FROM SIC_DESCRIPTIONS
					WHERE DESCRIPTION = <cfqueryparam value='#description#' />
				</cfquery>
				<cfset sic = getSIC.SIC_CODE/>
				<cfset displayClassification = "No results for '" & classification & "'. Displaying results for '" & description & "'"/>

			</cfif> <!--- end check hidden values --->

		<cfelse>
			<!--- input valid --->
			<!--- update sic and decription if needed --->
			<cfif description NEQ classification>
				<cfset description = #classification#/>
				<cfset sic = verifyClassification.SIC_CODE/>
			</cfif>

		</cfif> <!--- end check user input --->

		<!---
			All user input should now be verified.
			Update the title and description for the page and continue
			with results selection.
			Two main queries for results: getListings_amountafterfilter and getListings
			The first let's us define our totalResults count.
			The second contains all our records in order to display on results page. The order needs
			to have our customers first, with the largest ad sizes first among our customers. After that
			all records are displayed in alphabetical order by company name.
		--->

		<!--- Dynamic metadata --->
		<cfset workingTitle = 'Search for local ' & description & ' in or near ' & city & ', ' & state & '.' & '| Original Yellow - Official Site'/>
		<cfset workingDescription = 'Local ' & description & ' in or near ' & city & ', ' & state & '.'/>
		<cfset workingKeywords = 'yp, yellow pages, original yellow, original yellow pages, the original yp network, the original yellow pages network, search, directory services, simple search, local search, regional search, national search, online advertising, yellow page directory, directory, online directory, online business directory, free business listing, online business listing, local businesses, usa, ' & description & ', ' & city & ', ' & state />
		<!--- end metadata --->

		<cfquery name="getListings_amountafterfilter" datasource="memory">
			SELECT COUNT(*) as totalRecords
			FROM [dbo].[#state#]
			WHERE SIC_1 = <cfqueryparam value='#sic#' />
			<cfif isnumeric(ddLetter)>
				AND Left(COMPANY, 1) IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0')
			<cfelseif ddLetter NEQ "">
				AND Left(COMPANY, 1) = <cfqueryparam value='#ddLetter#' />
			</cfif>

			<cfif ddCompany NEQ "">
				AND COMPANY LIKE <cfqueryparam value='#ddCompany#%' />
			</cfif>

			<cfif ddAreaCode NEQ "">
					AND LEFT(PHONE, 3) LIKE '#ddAreaCode#%'
				</cfif>


			<cfif ddSpecialty NEQ "">
				AND SPECIALTY LIKE <cfqueryparam value='#ddSpecialty#%' />
			</cfif>
			<cfif cityUnabbreviated NEQ "">
				AND CITY LIKE '#city#' OR CITY = <cfqueryparam value='#cityUnabbreviated#' />
			<cfelse>
				AND CITY LIKE <cfqueryparam value='#city#' />
			</cfif>
			AND STATE = <cfqueryparam value='#state#' />
		</cfquery>

		<cfset totalRecords = getListings_amountafterfilter.totalRecords/>

		<cfquery name="getListings" datasource="memory">
			SELECT ID,
				MAILFILE_ID,
				COMPANY,
				ADDRESS1,
				CITY,
				STATE,
				ZIP,
				PHONE,
				TOLLFREE,
				SIC_1,
				CLASSIFICATION_1,
				WEBADDR,
				CUST_TYPE,
				AD_SIZE,
				SPECIALTY
			FROM (SELECT top #totalRecords# *,
				LEFT(PHONE,3) AS AREACODE,
				ROW_NUMBER() OVER (
					-- orders customers first using row column
					ORDER BY CUST_TYPE DESC, AD_SIZE DESC, COMPANY
				) AS row
				FROM [dbo].[#state#]
				WHERE SIC_1 = <cfqueryparam value='#sic#' />
					-- letter filter
					<cfif isnumeric(ddLetter)>
						AND Left(COMPANY, 1) IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0')
					<cfelseif ddLetter NEQ "">
						AND Left(COMPANY, 1) = <cfqueryparam value='#ddLetter#' />
					</cfif>

					-- specialty filter
					<cfif ddSpecialty NEQ "">
						AND SPECIALTY LIKE <cfqueryparam value='#ddSpecialty#%' />
					</cfif>

					<cfif cityUnabbreviated NEQ "">
						AND CITY LIKE '#city#' OR CITY = <cfqueryparam value='#cityUnabbreviated#' />
					<cfelse>
						AND CITY LIKE <cfqueryparam value='#city#' />
					</cfif>
					AND STATE = <cfqueryparam value='#state#' />

					-- zip code filter
					<cfif ddZIPCode NEQ "">
						AND ZIP LIKE <cfqueryparam value='#ddZIPCode#%' />
					</cfif>

					--company filter
			<cfif ddCompany NEQ "">
				AND COMPANY LIKE <cfqueryparam value='#ddCompany#%' />
			</cfif>

			--area code filter
			<cfif ddAreaCode NEQ "">
					AND LEFT(PHONE, 3) LIKE '#ddAreaCode#%'
				</cfif>


				ORDER BY AD_SIZE DESC, company ASC) AS presort
			WHERE row > <cfqueryparam value='#startRow#'/> AND row <= <cfqueryparam value='#endRow#' />
			ORDER BY row

		</cfquery>

		<!--- Search by letters --->
		<cfquery name="containsLetters" datasource="memory">
			SELECT DISTINCT LEFT(COMPANY,1) AS LETTER
			FROM (SELECT top #totalRecords# *,
				LEFT(PHONE,3) AS AREACODE
				FROM [dbo].[#state#]
				WHERE SIC_1 = <cfqueryparam value='#sic#'/>

				-- letter filter
				<cfif isnumeric(ddLetter)>
					AND Left(COMPANY, 1) IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0')
				<cfelseif ddLetter NEQ "">
					AND Left(COMPANY, 1) = <cfqueryparam value='#ddLetter#'/>
				</cfif>

				-- specialty filter
				<cfif ddSpecialty NEQ "">
					AND SPECIALTY LIKE <cfqueryparam value='#ddSpecialty#%' />
				</cfif>

			<cfif ddCompany NEQ "">
				AND COMPANY LIKE <cfqueryparam value='#ddCompany#%' />
			</cfif>

			<cfif ddAreaCode NEQ "">
					AND LEFT(PHONE, 3) LIKE '#ddAreaCode#%'
				</cfif>


				<cfif cityUnabbreviated NEQ "">
					AND CITY LIKE <cfqueryparam value='#city#' /> OR CITY = <cfqueryparam value='#cityUnabbreviated#'/>
				<cfelse>
					AND CITY LIKE <cfqueryparam value='#city#'/>
				</cfif>

				AND STATE = '#state#'

				-- zip code filter
				<cfif ddZIPCode NEQ "">
					AND ZIP LIKE <cfqueryparam value='#ddZIPCode#%'/>
				</cfif>
				ORDER BY AD_SIZE DESC, company ASC) AS presort
			ORDER BY LETTER
		</cfquery>

		<cfset numberFound = false>
		<cfset session.letterArray = arrayNew(1)>

		<cfloop query="containsLetters">
			<cfif isnumeric(LETTER) and numberFound EQ false>
				<cfset numberFound = true>
				<cfset session.letterArray[arrayLen(session.letterArray)+1] = "0">
			<cfelse>
				<cfset session.letterArray[arrayLen(session.letterArray)+1] = "#LETTER#">
			</cfif>
		</cfloop>
		<!--- end Search by letters --->

		<!---
			NOTE: Here is also where we could save our customers "page rank" for searches on our sites using the
			"row" column in getListings. Rather than parsing pmfid in iis logs.
		--->

		<!--- get remaining URL/filter parameters --->
		<!--- get specialties for filter option --->
		<cfquery name="getSpecialties" datasource="memory">
			SELECT DISTINCT SPECIALTY
			FROM [dbo].[#state#]
			WHERE SIC_1 = <cfqueryparam value='#sic#'/> AND CITY LIKE <cfqueryparam value='#city#'/> AND STATE = <cfqueryparam value='#state#'/>
				AND SPECIALTY IS NOT NULL AND SPECIALTY != ''
			ORDER BY SPECIALTY
		</cfquery>

		<!--- get pmfid from current page listings --->
		<cfloop index="i" from="1" to="#getListings.recordCount#">
			<cfset PMFID = PMFID & #getListings["ID"][i]# & "_"/>
		</cfloop>
		<cfset PMFID NEQ "" ? PMFID = left(PMFID, len(PMFID)-1) : ""/>

		<!---
			Update url to include pmfid.
			For navigation buttons, leave this as empty string.
			New url with pmfid param is loaded whenever pmfid = ""
			Do not include startRow or resultsPerPage in nav links or there will be duplicates/errors when links clicked.
		--->

		<cfif city EQ "%">
			<cfset city = "@toyp-stateSearch"/>
		</cfif>

		<cfset resultsNavURL = "records?location=#location#&classification=#classification#&city=#city#&state=#state#&zip=#zip#&sic=#sic#&description=#description#&mailfile_id=#mailfile_id#&topLocation=#topLocation#&topClassification=#topClassification#&ddZIPCode=#ddZIPCode#&ddAreaCode=#ddAreaCode#&ddCompany=#ddCompany#"/>

		<cfset resultsURL = "records?location=#location#&classification=#classification#&city=#city#&state=#state#&zip=#zip#&sic=#sic#&description=#description#&mailfile_id=#mailfile_id#&topLocation=#topLocation#&topClassification=#topClassification#&pmfid=#pmfid#&startRow=#startRow#&resultsPerPage=#resultsPerPage#&ddLetter=#ddLetter#&ddSpecialty=#ddSpecialty#&ddCompany=#ddCompany#&ddZIPCode=#ddZIPCode#&ddAreaCode=#ddAreaCode#"/>

		<!--- update location to URL w/ PMFID for tracking --->
		<cfif URL.PMFID EQ "" and getListings.recordCount GT 0>
		    <cflocation url="#resultsURL#">
	    </cfif>

		<!---
			The next step is to get all ads for the page.
			Currently there are at max 3 ads on the records page; 2 leaderboards & 1 standard.
			 1. All ad info will be stored in the adPool array. Get a list of all active customers with valid standard, leaderboard, and skyline ad files.
				Save the respective mailfile id's to adPool. adPool is then shuffled so new ads appear on every page load.
			 2. Loop over the amount of ads that we want on the records page, this value is stored in adsPerPage.
				A random record is selected from the adPool, and the company info (as a query), standard img path, skyline img path, and leaderboard img
				path are then stored in an array and pushed into the ads "array".
			 3. All advertisement information can then be retrieved from "ads" in the view.
	 	--->

		<cfif Len(location) EQ 2> <!--- IF JUST A STATE ABBREVIATION --->
			<cfset state = "#location#">
		</cfif>

		<cfquery name="adquery" datasource="oes">
			SELECT DISTINCT MAILFILE_ID, COMPANY, CITY, STATE
			FROM CUSTOMERS
			WHERE PRIORITY = 'COMPLETED' AND STATUS = 'ACTIVE'
			<cfif state NEQ "DC">
				AND STATE = <cfqueryparam value='#state#'/>
			</cfif>
		</cfquery>

		<cfif adquery.recordCount EQ 0>
			<cfquery name="adquery" datasource="oes">
				SELECT DISTINCT MAILFILE_ID, COMPANY, CITY, STATE
				FROM CUSTOMERS
				WHERE PRIORITY = 'COMPLETED' AND STATUS = 'ACTIVE'
			</cfquery>
		</cfif>

		<!--- <cfabort showerror="#serialize(adquery)#"> --->

		<cfset adPool = arrayNew()/>
		<cfset adignoreList = ""/>
		<cfset adsPerPage = "3"/>
		<cfset ads = arrayNew()/>

		<!--- only use customers if all ad sizes valid, then shuffle array --->
		<cfloop index="i" from="1" to="#adquery.recordCount#">

			<!--- Check for special mailfile regions: CA, MD, US --->
			<cfset adRegion = #Left(adquery.Mailfile_ID,2)#/>
			<cfif #Left(adquery.Mailfile_ID,2)# EQ "CA">
				<cfset adRegion = "WC"/>
			</cfif>

			<cfif fileExists("c:\inetpub\wwwroot\graphics65wr\client_ads2_leaderboard\#adRegion#\#Mid(adquery.MAILFILE_ID,8,2)#\1UP\jpg\1UP_#adquery.Mailfile_ID#_leaderboard.jpg") AND fileExists("c:\inetpub\wwwroot\graphics65wr\client_ads2_skyline\#adRegion#\#Mid(adquery.MAILFILE_ID,8,2)#\1UP\jpg\1UP_#adquery.Mailfile_ID#_skyline.jpg")>
				<cfset adPool = adPool.append(QueryRowData(adquery, #i#)["MAILFILE_ID"])/>
			</cfif>
		</cfloop>

		<cfset createObject("java", "java.util.Collections").Shuffle(adPool)/>

		<!---
			There should be at least 2 active customer with ads for every state.
			Use below SQL to double check
			SELECT DISTINCT COUNT(MAILFILE_ID) as n, STATE
			FROM CUSTOMERS
			WHERE PRIORITY = 'COMPLETED' AND STATUS = 'ACTIVE'
			GROUP BY STATE
			ORDER BY n ASC
		--->

		<!--- final ads loop, all info stored in "ads" array --->
		<cfloop index="i" from="1" to="#min(adsPerPage, len(adPool))#">
			<cfset adObject = arrayNew()/>

			<!--- company info --->
			<cfquery name="adQuery" datasource="vweb">
				SELECT TOP 1 *
				FROM WEBMASTERDB
				WHERE MAILFILE_ID = <cfqueryparam value='#adPool[i]#'/>
			</cfquery>

			<!--- ad image paths --->
			<cfset standardPath = "1UP_#adQuery.Mailfile_ID#.jpg"/>
			<cfset skylinePath = "client_ads2_skyline/#Left(adQuery.Mailfile_ID,2)#/#Mid(adQuery.MAILFILE_ID,8,2)#/1UP/jpg/1UP_#adQuery.Mailfile_ID#_skyline.jpg"/>
			<cfset leaderboardPath = "client_ads2_leaderboard/#Left(adQuery.Mailfile_ID,2)#/#Mid(adQuery.MAILFILE_ID,8,2)#/1UP/jpg/1UP_#adQuery.Mailfile_ID#_leaderboard.jpg"/>

			<!--- append ads array with adObject array --->
			<cfset adObject = adObject.append(adQuery)/>
			<cfset adObject = adObject.append(standardPath)/>
			<cfset adObject = adObject.append(skylinePath)/>
			<cfset adObject = adObject.append(leaderboardPath)/>
			<cfset ads = ads.append(adObject)/>
		</cfloop>

	</cffunction>

<!--- ----------------------------------------------------------------------------------------- --->
	<cffunction name="getSpecialties">
		<cfreturn />
	</cffunction>
<!--- ----------------------------------------------------------------------------------------- --->
</cfcomponent>
