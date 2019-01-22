# encoding: utf-8
require 'require_all'
require_all './Repository'
require 'date'

class GitProject

	def initialize(project, localClone, login, password)
			@projetcName = project
			@localClone = localClone
			@path = cloneProjectLocally(project, localClone)
			@login = login
			@password = password
	end
	

	def getLogin()
		@login
	end

	def getPassword()
		@password
	end

	def getPath()
		@path
	end


	def getLocalClone()
		@localClone
	end

	def getProjectName()
		@projetcName
	end

	def getMergeScenarios()
		@mergeScenarios
	end

	def getMergeCommitParents()
		@mergeCommitParents
	end

	def cloneProjectLocally(project, localClone)
		Dir.chdir localClone 
		if File.directory?("localProject")
			#delete = %x(rd /s /q localProject) # windows use
			delete = %x(rm -rf localProject) # linux use
			puts "local was deleted before clonning" #debugging...
		end
		clone = %x(git clone https://github.com/#{project} localProject)
		Dir.chdir "localProject"
		return Dir.pwd
	end

	def deleteProject()
		Dir.chdir getLocalClone()
		#delete = %x(rd /s /q localProject) # windows use
		delete = %x(rm -rf localProject) # linux use
	end


	def formatProjectName(projectName)
	  #return projectName[0..projectName.index('/')-1]
		return projectName[projectName.index('/')+1..projectName.length]
	end
	
	# Number of commits
	def generateCommitsNumberByMergeScenario(projectName, localClone, pathInput, pathOutput)
		prefixProjectName = formatProjectName(projectName)
		projectsList = []
		File.open(localClone+pathInput+prefixProjectName+"_MergeScenarioList.csv", "r") do |text|
			#indexLine = 0
			text.gets
			text.each_line do |line|
				lista = line.split(",")
				mergeCommitID = lista[0].gsub("\r","").gsub("\n","")
				isMergeConflicting = lista[1].gsub("\r","").gsub("\n","")
				left = lista[3].gsub("\r","").gsub("\n","")
				right = lista[5].gsub("\r","").gsub("\n","")
				ancestor = %x(git merge-base #{left} #{right}).gsub("\r","").gsub("\n","")

				countLeftCommits = %x(git rev-list --count #{ancestor}..#{left} ).gsub("\r","").gsub("\n","")
				listLeftCommits = %x(git rev-list #{ancestor}..#{left} ).gsub("\n","@@")#.split("\n").length	

				countRightCommits = %x(git rev-list --count #{ancestor}..#{right}).gsub("\r","").gsub("\n","")
				listRightCommits = %x(git rev-list #{ancestor}..#{right}).gsub("\n","@@")#.split("\n").length

				if !countLeftCommits.eql? "0" and  !countRightCommits.eql? "0" #pra que esse if?? nao faz sentido!!!!
					sumMergeCommits = Integer(countLeftCommits) + Integer(countRightCommits)
					arithmeticMeanMergeCommits = (Float(Integer(countLeftCommits) + Integer(countRightCommits))/2).round(2) # for extra evaluation purposes
					geometricMeanMergeCommits =  Math.sqrt(Float(Integer(countLeftCommits)*Integer(countRightCommits))).round(2)
					dados = mergeCommitID+","+isMergeConflicting+","+left+","+right+","+ancestor+","+countLeftCommits+","+countRightCommits+","+"#{sumMergeCommits}"+","+"#{arithmeticMeanMergeCommits}"+","+"#{geometricMeanMergeCommits}"+","+listLeftCommits+","+listRightCommits
					projectsList.push(dados.gsub("\n", ""))
				end
			end
		end

		 File.open(localClone+pathOutput+prefixProjectName+"_CommitList.csv", 'w') do |file|
			file.puts "MergeCommitID, isMergeConflicting, left, right, ancestor, countLeftCommits, countRightCommits, sumMergeCommits, arithmeticMeanMergeCommits, geometricMeanMergeCommits, listLeftCommits,listRightCommits"
			projectsList.each do |dado|
				file.puts "#{dado}"
			end
		 end
		puts "end running generateCommitsNumberByMergeScenario from #{prefixProjectName} project"
	end


	# Number of developers
	def generateAuthorsNumberByMergeScenario(projectName, localClone, pathOutput)
		prefixProjectName = formatProjectName(projectName)
	  authorsFile = []
		File.open(localClone+pathOutput+prefixProjectName+"_CommitList.csv", 'r') do |f1| 
		 while line = f1.gets 
			f1.each_line do |line|
				leftAuthorsList = []
		    rightAuthorsList = []
				campos = line.split(",")#.length

				leftCommits = campos[10].split("@@")
				rightCommits = campos[11].split("@@")
					
				if leftCommits.include?("\n")
					leftCommits.delete("\n")
				end
				
				if rightCommits.include?("\n")
					rightCommits.delete("\n")
				end
				
				leftCommits.each do |commit|
					autorLeft = %x(git --no-pager log -1 --pretty=format:"%an (%ae)" #{commit}).gsub("\r","").gsub("\n","")
					leftAuthorsList.push(autorLeft.gsub("\n", ""))
				end
				rightCommits.each do |commit|
					autorRight = %x(git --no-pager log -1 --pretty=format:"%an (%ae)" #{commit}).gsub("\r","").gsub("\n","")
					rightAuthorsList.push(autorRight.gsub("\n", ""))
				end
				sumMergeAuthors = Integer(leftAuthorsList.uniq.length) + Integer(rightAuthorsList.uniq.length)
				arithmeticMeanMergeAuthors = (Float(Integer(leftAuthorsList.uniq.length) + Integer(rightAuthorsList.uniq.length))/2).round(2) # for extra evaluation purposes
				geometricMeanMergeAuthors =  Math.sqrt(Float(Integer(leftAuthorsList.uniq.length)*Integer(rightAuthorsList.uniq.length))).round(2)
				linha =  campos[0]+","+campos[1]+","+"#{leftAuthorsList.uniq.length}"+","+"#{rightAuthorsList.uniq.length}"+","+"#{sumMergeAuthors}"+","+"#{arithmeticMeanMergeAuthors}"+","+"#{geometricMeanMergeAuthors}"+","+"#{leftAuthorsList.uniq}".gsub(",","-")+","+"#{rightAuthorsList.uniq}".gsub(",","-")
				authorsFile.push(linha.gsub("\n", ""))
			end 
		 end 
		end 
		
		 File.open(localClone+pathOutput+prefixProjectName+"_AuthorList.csv", 'w') do |file|
			file.puts "MergeCommitID, isMergeConflicting, leftAuthorsListLength, rightAuthorsListLength, sumMergeAuthors, arithmeticMeanMergeAuthors, geometricMeanMergeAuthors, leftAuthorsList, rightAuthorsList"
			authorsFile.each do |dado|
				file.puts "#{dado}"
			end
		 end		
		puts "end running generateAuthorsNumberByMergeScenario from #{prefixProjectName} project"
	end

	
	# Deprecated - metrics not used in this paper - only for extra evaluation purposes
	def generateDelayToIntegrationByMergeScenario(projectName, localClone, pathOutput)
		puts "running generateDelayToIntegrationByMergeScenario from #{projectName} project"

		prefixProjectName = formatProjectName(projectName)
		integrationLine = []
		integrationLineAuthorDateList = []
		integrationLineCommitDateList = []

		File.open(localClone+pathOutput+prefixProjectName+"_CommitList.csv", 'r') do |f1|
		 while line = f1.gets 
			f1.each_line do |line|
				leftAuthorsList = []
		    rightAuthorsList = []
				campos = line.split(",")#.length	
				mergeCommitID = campos[0].gsub("\r","").gsub("\n","")
				isConflicting = campos[1].gsub("\r","").gsub("\n","")
				leftCommits = campos[10].split("@@")
				rightCommits = campos[11].split("@@")
        leftDelayIntegration = 0
				rightDelayIntegration = 0
				arithmeticMeanDelayIntegration = 0 # for extra evaluation purposes
				geometricMeanDelayIntegration = 0
				deltaIntegration = 0

				if leftCommits.include?("\n")
					leftCommits.delete("\n")
				end
				
				if rightCommits.include?("\n")
					rightCommits.delete("\n")
				end
				
				# Metric
					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{leftCommits[0]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{mergeCommitID}).gsub("\r","").gsub("\n","")
					leftDelayIntegration = (endDate - startDate).to_i.abs
					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{rightCommits[0]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{mergeCommitID}).gsub("\r","").gsub("\n","")
					rightDelayIntegration = (endDate - startDate).to_i.abs

					if (leftDelayIntegration==0)
						leftDelayIntegration = 1
					end

					if (rightDelayIntegration==0)
						rightDelayIntegration = 1
					end

					if leftDelayIntegration > rightDelayIntegration
						deltaIntegration = leftDelayIntegration - rightDelayIntegration
					elsif rightDelayIntegration > leftDelayIntegration
						deltaIntegration = rightDelayIntegration - leftDelayIntegration
					else
						deltaIntegration = 0
					end

					arithmeticMeanDelayIntegration = (Float(leftDelayIntegration + rightDelayIntegration)/2).round(2) # for extra evaluation purposes
					geometricMeanDelayIntegration =  Math.sqrt(Float(leftDelayIntegration*rightDelayIntegration)).round(2)
					linha = mergeCommitID+","+isConflicting+","+leftDelayIntegration.to_s+","+rightDelayIntegration.to_s+","+arithmeticMeanDelayIntegration.to_s+","+geometricMeanDelayIntegration.to_s+","+deltaIntegration.to_s
					integrationLine.push(linha.gsub("\n", ""))		
					
					 File.open(localClone+pathOutput+prefixProjectName+"_DelayDeltaIntegrationList.csv", 'w') do |file|
						file.puts "mergeCommitID, isConflicting, leftDelayIntegration, rightDelayIntegration, arithmeticMeanDelayIntegration, geometricMeanDelayIntegration, deltaIntegration"
						integrationLine.each do |dado|
							file.puts "#{dado}"
						end
					 end				 

				# exploring more data - extra internal test
					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{leftCommits[0]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{mergeCommitID}).gsub("\r","").gsub("\n","")
					leftDelayIntegration = (endDate - startDate).to_i.abs

					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{rightCommits[0]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{mergeCommitID}).gsub("\r","").gsub("\n","")
					rightDelayIntegration = (endDate - startDate).to_i.abs

					if leftDelayIntegration > rightDelayIntegration
						deltaIntegration = leftDelayIntegration - rightDelayIntegration
					elsif rightDelayIntegration > leftDelayIntegration
						deltaIntegration = rightDelayIntegration - leftDelayIntegration
					else
						deltaIntegration = 0
					end
					
					arithmeticMeanDelayIntegration = (Float(leftDelayIntegration + rightDelayIntegration)/2).round(2) # for extra evaluation purposes
					geometricMeanDelayIntegration =  Math.sqrt(Float(leftDelayIntegration*rightDelayIntegration)).round(2)				
					
					linha = mergeCommitID+","+isConflicting+","+leftDelayIntegration.to_s+","+rightDelayIntegration.to_s+","+arithmeticMeanDelayIntegration.to_s+","+geometricMeanDelayIntegration.to_s+","+deltaIntegration.to_s
					integrationLineCommitDateList.push(linha.gsub("\n", ""))		
					
					 File.open(localClone+pathOutput+prefixProjectName+"_DelayDeltaIntegrationCommitDatesList.csv", 'w') do |file|
						file.puts "mergeCommitID, isConflicting, leftDelayIntegration, rightDelayIntegration, arithmeticMeanDelayIntegration, geometricMeanDelayIntegration, deltaIntegration"
						integrationLineCommitDateList.each do |dado|
							file.puts "#{dado}"
						end
					 end


				# exploring more data - extra test
					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{leftCommits[0]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{mergeCommitID}).gsub("\r","").gsub("\n","")
					leftDelayIntegration = (endDate - startDate).to_i.abs

					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{rightCommits[0]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{mergeCommitID}).gsub("\r","").gsub("\n","")
					rightDelayIntegration = (endDate - startDate).to_i.abs

					if leftDelayIntegration > rightDelayIntegration
						deltaIntegration = leftDelayIntegration - rightDelayIntegration
					elsif rightDelayIntegration > leftDelayIntegration
						deltaIntegration = rightDelayIntegration - leftDelayIntegration
					else
						deltaIntegration = 0
					end
					
					arithmeticMeanDelayIntegration = (Float(leftDelayIntegration + rightDelayIntegration)/2).round(2) # for extra evaluation purposes
					geometricMeanDelayIntegration =  Math.sqrt(Float(leftDelayIntegration*rightDelayIntegration)).round(2)				
					
					linha = mergeCommitID+","+isConflicting+","+leftDelayIntegration.to_s+","+rightDelayIntegration.to_s+","+arithmeticMeanDelayIntegration.to_s+","+geometricMeanDelayIntegration.to_s+","+deltaIntegration.to_s
					integrationLineAuthorDateList.push(linha.gsub("\n", ""))		
					
					 File.open(localClone+pathOutput+prefixProjectName+"_DelayDeltaIntegrationAuthorDatesList.csv", 'w') do |file|
						file.puts "mergeCommitID, isConflicting, leftDelayIntegration, rightDelayIntegration, arithmeticMeanDelayIntegration, geometricMeanDelayIntegration, deltaIntegration"
						integrationLineAuthorDateList.each do |dado|
							file.puts "#{dado}"
						end
					 end				 

			end #f1eachline
		 end #while
		end #Fileopen
	puts "end running generateDelayToIntegrationByMergeScenario from #{prefixProjectName} project"
	end #method


	# Conclusion delay
	def generateContributionConclusionDelayByMergeScenario(projectName, localClone, pathOutput)
		prefixProjectName = formatProjectName(projectName)
		integrationLine = []

		File.open(localClone+pathOutput+prefixProjectName+"_CommitList.csv", 'r') do |f1|
			while line = f1.gets
				f1.each_line do |line|
					campos = line.split(",")#.length
					mergeCommitID = campos[0].gsub("\r","").gsub("\n","")
					isConflicting = campos[1].gsub("\r","").gsub("\n","")
					leftCommits = campos[10].split("@@")
					rightCommits = campos[11].split("@@")

					contributionConclusionDelay = 0

					if leftCommits.include?("\n")
						leftCommits.delete("\n")
					end

					if rightCommits.include?("\n")
						rightCommits.delete("\n")
					end


					leftDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{leftCommits[0]}).gsub("\r","").gsub("\n","")
					rightDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{rightCommits[0]}).gsub("\r","").gsub("\n","")

					if leftDate > rightDate
						contributionConclusionDelay = (leftDate - rightDate).to_i.abs
					elsif rightDate > leftDate
						contributionConclusionDelay = (rightDate - leftDate).to_i.abs
					else
						contributionConclusionDelay = 0
					end

					linha = mergeCommitID+","+isConflicting+","+leftDate.to_s+","+rightDate.to_s+","+contributionConclusionDelay.to_s
					integrationLine.push(linha.gsub("\n", ""))

					File.open(localClone+pathOutput+prefixProjectName+"_ContributionConclusionDelayList.csv", 'w') do |file|
						file.puts "mergeCommitID, isConflicting, leftDate, rightDate, contributionConclusionDelay"
						integrationLine.each do |dado|
							file.puts "#{dado}"
						end
					end

				end #f1eachline
			end #while
		end #Fileopen
		puts "end running generateContributionConclusionDelayByMergeScenario from #{prefixProjectName} project"
	end #method


	# Duration
	def generateLifetimeContributionByMergeScenario(projectName, localClone, pathOutput)
		prefixProjectName = formatProjectName(projectName)
		integrationLine = []
		integrationLineCommiDateList = []
		integrationLineAuthorDateList = []

		File.open(localClone+pathOutput+prefixProjectName+"_CommitList.csv", 'r') do |f1|
		 while line = f1.gets 
			f1.each_line do |line|
				leftAuthorsList = []
	      rightAuthorsList = []
				campos = line.split(",")#.length	
				mergeCommitID = campos[0].gsub("\r","").gsub("\n","")
				isConflicting = campos[1].gsub("\r","").gsub("\n","")
				leftCommits = campos[10].split("@@")
				rightCommits = campos[11].split("@@")
        leftLifetime = 0
				rightLifetime = 0
				arithmeticMeanLifetime = 0 # for extra evaluation purposes
				geometricMeanLifetime = 0
				deltaLifetime = 0
				

				if leftCommits.include?("\n")
					leftCommits.delete("\n")
				end
				
				if rightCommits.include?("\n")
					rightCommits.delete("\n")
				end

				# not used in the paper- for extra evaluation purposes
				if leftCommits.length == 1
					leftLifetime = 1
				else
					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{leftCommits[leftCommits.length-1]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{leftCommits[0]}).gsub("\r","").gsub("\n","")
					leftLifetime = (endDate - startDate).abs.to_i
				end
						
				if rightCommits.length == 1
					rightLifetime = 1
				else
					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{rightCommits[rightCommits.length-1]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%cd" --date=local #{rightCommits[0]}).gsub("\r","").gsub("\n","")					
					rightLifetime = (endDate - startDate).abs.to_i
				end
				
				arithmeticMeanLifetime = (Float(leftLifetime + rightLifetime)/2).round(2) # for extra evaluation purposes
				geometricMeanLifetime =  Math.sqrt(Float(leftLifetime*rightLifetime)).round(2)	

				if leftLifetime > rightLifetime
					deltaLifetime = leftLifetime - rightLifetime
				elsif rightLifetime > leftLifetime
					deltaLifetime = rightLifetime - leftLifetime
				else
					deltaLifetime = 0
				end 
			

				linha = mergeCommitID+","+isConflicting+","+leftLifetime.to_s+","+rightLifetime.to_s+","+arithmeticMeanLifetime.to_s+","+geometricMeanLifetime.to_s+","+deltaLifetime.to_s
				integrationLineCommiDateList.push(linha.gsub("\n", ""))						
				File.open(localClone+pathOutput+prefixProjectName+"_LifetimeCommitDateList.csv", 'w') do |file|
					file.puts "mergeCommitID, isConflicting, leftLifetime, rightLifetime, arithmeticMeanLifetime, geometricMeanLifetime, deltaLifetime"
					integrationLineCommiDateList.each do |dado|
						file.puts "#{dado}"
					end
				end

							    
				# metric used in the paper
				if leftCommits.length == 1
					leftLifetime = 1
				else
					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{leftCommits[leftCommits.length-1]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{leftCommits[0]}).gsub("\r","").gsub("\n","")
					leftLifetime = (endDate - startDate).abs.to_i
				end
				
						
				if rightCommits.length == 1
					rightLifetime = 1
				else
					startDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{rightCommits[rightCommits.length-1]}).gsub("\r","").gsub("\n","")
					endDate = Date.parse %x(git --no-pager log -1 --pretty=format:"%ad" --date=local #{rightCommits[0]}).gsub("\r","").gsub("\n","")					
					rightLifetime = (endDate - startDate).abs.to_i
				end

				if (leftLifetime == 0)
					leftLifetime = 1
				end
				if (rightLifetime == 0)
					rightLifetime = 1
				end
			
				arithmeticMeanLifetime = (Float(leftLifetime + rightLifetime)/2).round(2) # for extra evaluation purposes
				geometricMeanLifetime =  Math.sqrt(Float(leftLifetime*rightLifetime)).round(2)	

				# not used in the paper- for extra evaluation purposes
				if leftLifetime > rightLifetime
					deltaLifetime = leftLifetime - rightLifetime
				elsif rightLifetime > leftLifetime
					deltaLifetime = rightLifetime - leftLifetime
				else
					deltaLifetime = 0
				end 
			
				linha = mergeCommitID+","+isConflicting+","+leftLifetime.to_s+","+rightLifetime.to_s+","+arithmeticMeanLifetime.to_s+","+geometricMeanLifetime.to_s+","+deltaLifetime.to_s
				integrationLineAuthorDateList.push(linha.gsub("\n", ""))						
				File.open(localClone+pathOutput+prefixProjectName+"_LifetimeAuthorDateList.csv", 'w') do |file|
					file.puts "mergeCommitID, isConflicting, leftLifetime, rightLifetime, arithmeticMeanLifetime, geometricMeanLifetime, deltaLifetime"
					integrationLineAuthorDateList.each do |dado|
						file.puts "#{dado}"
					end
				end
			end #f1eachline
		 end #while
		end #Fileopen
		puts "end running generateLifetimeContributionByMergeScenario from #{prefixProjectName} project"
	end #method


	# Changed Files and Lines
	def getNumberOfChangedFilesAndChangedLines (projectName, localClone, pathInput, pathOutput)
	 prefixProjectName = formatProjectName(projectName)
		filesList = []
		dataList = []
		countTemp = 0
		#_ParentsFiles
		File.open(localClone+pathOutput+prefixProjectName+"_CommitList.csv", 'r') do |fileMerges| 
			while line = fileMerges.gets 
				fileMerges.each_line do |line|
					camposMerge = line.split(",")
					File.open(localClone+pathInput+prefixProjectName+"_MergeScenarioList.csv", 'r') do |fileTEMP|
						while lineTEMP = fileTEMP.gets 
							fileTEMP.each_line do |lineTEMP|
								camposParents = lineTEMP.split(",")
								if (camposMerge[0].eql? camposParents[0])
									data = camposMerge[0].gsub("\"", "").gsub("\n","")+","+camposMerge[1].gsub("\"", "").gsub("\n","")+","+camposMerge[10].gsub("\"", "").gsub("\n","")+","+camposMerge[11].gsub("\"", "").gsub("\n","")+","+camposParents[4].gsub("\"", "").gsub("\n","")+","+camposParents[6].gsub("\"", "").gsub("\n","")
									dataList.push(data)
									countTemp +=1
							    end
							end
						end
					end
				end
			end
		end

		File.open(localClone+pathOutput+prefixProjectName+"_CommitListAndFilesList.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, listLeftCommits, listRightCommits, leftFiles, rightFiles"
			dataList.each do |dado|
				file.puts "#{dado}"
			end
		end
		
		projectsList = []
		File.open(localClone+pathOutput+prefixProjectName+"_CommitListAndFilesList.csv", 'r') do |f1| 
			while line = f1.gets 
				f1.each_line do |line|
					campos = line.split(",")#.length	
					mergeCommitID = campos[0].gsub("\r","").gsub("\n","")
					isConflicting = campos[1].gsub("\r","").gsub("\n","")
					leftCommits = campos[2].split("@@")
					rightCommits = campos[3].split("@@")
					
				
					leftFiles = campos[4][1..campos[4].length-2].split("@")				
					if !campos[5].include?("\n")
						rightFiles = campos[5][1..campos[5].length-2].split("@")
					else
						rightFiles = campos[5][1..campos[5].length-3].split("@")
					end	

					#leftFiles=[]
					countLeftLines =0
					countRightLines=0
					#rightFiles
					arithmeticMeanChangedFiles = 0 # for extra evaluation purposes
					geometricMeanChangedFiles = 0				
					
					if leftCommits.include?("\n")
						leftCommits.delete("\n")
					end					
					if rightCommits.include?("\n")
						rightCommits.delete("\n")
					end
			
					leftCommits.each do |commit|
						data =  %x(git --no-pager log -1 --stat #{commit})
						listInfo = data.split("\n")
						changesSummary = listInfo[listInfo.size-1]
						changesList = changesSummary.split(",")

						if (changesList.size == 3) # both insertions and deletions
							countLeftLines += changesList[1].split(" ")[0].to_i + changesList[2].split(" ")[0].to_i
						elsif ((changesList.size == 2))
							countLeftLines += changesList[1].split(" ")[0].to_i
						end

					end

					rightCommits.each do |commit|
						data =  %x(git --no-pager log -1 --stat #{commit})
						listInfo = data.split("\n")
						changesSummary = listInfo[listInfo.size-1]
						changesList = changesSummary.split(",")

						if (changesList.size == 3) # both insertions and deletions
							countRightLines += changesList[1].split(" ")[0].to_i + changesList[2].split(" ")[0].to_i
						elsif ((changesList.size == 2))
							countRightLines += changesList[1].split(" ")[0].to_i
						end

					end


					arithmeticMeanChangedLines = (Float(countLeftLines + countRightLines)/2).round(2) # for extra evaluation purposes
					geometricMeanChangedLines =  Math.sqrt(Float(countLeftLines*countRightLines)).round(2)
					dados = mergeCommitID+","+isConflicting+","+"#{countLeftLines}"+","+"#{countRightLines}"+","+"#{arithmeticMeanChangedLines}"+","+"#{geometricMeanChangedLines}"
					projectsList.push(dados.gsub("\"", ""))
				end
			end
		end
		File.open(localClone+pathOutput+prefixProjectName+"_NumberOfChangedLines.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, countLeftLines, countRightLines, arithmeticMeanChangedLines, geometricMeanChangedLines"
			projectsList.each do |dado|
				file.puts "#{dado}"
			end
		end


		projectsList = []
		projectsFilesList = []
		File.open(localClone+pathOutput+prefixProjectName+"_CommitListAndFilesList.csv", 'r') do |f1| 
			while line = f1.gets 
				f1.each_line do |line|
					campos = line.split(",")#.length	
					mergeCommitID = campos[0].gsub("\r","").gsub("\n","")
					isConflicting = campos[1].gsub("\r","").gsub("\n","")
				
				
					leftFiles = campos[4].split("@")	
					rightFiles = campos[5].split("@")					
					
					
					countLeftFiles = leftFiles.length
					countRightFiles = rightFiles.length
					
					arithmeticMeanChangedFiles = 0 # for extra evaluation purposes
					geometricMeanChangedFiles = 0				
					

					arithmeticMeanChangedFiles = (Float(countLeftFiles + countRightFiles)/2).round(2) # for extra evaluation purposes
					geometricMeanChangedFiles =  Math.sqrt(Float(countLeftFiles*countRightFiles)).round(2)
					dados = mergeCommitID+","+isConflicting+","+"#{countLeftFiles}"+","+"#{countRightFiles}"+","+"#{arithmeticMeanChangedFiles}"+","+"#{geometricMeanChangedFiles}"
					projectsFilesList.push(dados.gsub("\"", ""))
				end
			end
		end

		File.open(localClone+pathOutput+prefixProjectName+"_NumberOfChangedFiles.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, countLeftFiles, countRightFiles, arithmeticMeanChangedFiles, geometricMeanChangedFiles"
			projectsFilesList.each do |dado|
				file.puts "#{dado}"
			end
		end

	 puts "end running getNumberOfChangedFilesAndChangedLines from #{prefixProjectName} project"
	end


	# Generate a single CSV file (one for each project) with all grouped metrics for statistical analysis.

	def generateCVSToStatisticAnalysis (projectName, localClone, pathInput,pathOutput)
		prefixProjectName = formatProjectName(projectName)
		
		listSlices = []
		listConflictsAndFiles = []
		listNumberOfCommits = []
		listNumberOfAuthors = []
		listDelayDeltaIntegration = []
		listMinimumLifeTime = []
		listNmberOfChangedFiles = []
		listNumberOfChangedLines = []
		listContributionConclusionDelay = []
		listPackages = []

		File.open(localClone+pathOutput+prefixProjectName+"_CommitList.csv", 'r') do |mainMerges|
			while line = mainMerges.gets 
				mainMerges.each_line do |line|
					camposMainMerge = line.split(",")
					File.open(localClone+pathInput+prefixProjectName+".csv", 'r') do |auxMerges| 
						while lineAux = auxMerges.gets 
							auxMerges.each_line do |lineAux|
							camposAuxMerge = lineAux.split(",")
							if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
								mergeCommitID = camposMainMerge[0].gsub("\"","")
								isConflicting = "0"
								if camposMainMerge[1].gsub("\"","").eql?("true")
									isConflicting = "1"
								end
								existsCommonSlice = camposAuxMerge[2].gsub("\"","")
								totalCommonSlices = camposAuxMerge[3].gsub("\"","").gsub("\r","")
								dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices
								listSlices.push(dados)
							end
							end #each_line
						end #while
					end # File.open
				end #each_line
			end #while
		end # File.open

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_Slices.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices"
			listSlices.each do |dado|
				file.puts "#{dado}"
			end
		end

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_Slices.csv", 'r') do |mainMerges|
			#while line = mainMerges.gets 
				mainMerges.each_line do |line|
					camposMainMerge = line.split(",")
					dados=""
					if camposMainMerge[1].gsub("\"","").gsub("\n","").eql?("0")
						mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
						isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
						existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
						totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","")
						conflictingFilesNumber = "0"
						conflictsNumber = "0"
						dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber
						listConflictsAndFiles.push(dados)
					elsif camposMainMerge[1].gsub("\"","").gsub("\n","").eql?("1")					
						File.open(localClone+pathInput+prefixProjectName+"_MergeScenarioList.csv", 'r') do |auxMerges|
				#			while lineAux = auxMerges.gets 
								auxMerges.each_line do |lineAux|
									camposAuxMerge = lineAux.split(",")
									if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
										mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
										isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
										existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
										totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","")
										#conflictingFilesNumber = camposAuxMerge[1].gsub("\"","").gsub("\n","")
										conflictingFilesNumber = camposAuxMerge[2].to_s.split("@").length.to_s #.gsub("\"","").gsub("\n","")
										conflictsNumber = camposAuxMerge[8].gsub("\"","").gsub("\n","")
										dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber
										listConflictsAndFiles.push(dados)
									end
								end #each_line
			#				end #while
						end # File.open
					end# elsif
				end #each_line
		#	end #while
		end # File.open

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_ConflictingFilesAndConflicts.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices, conflictingFilesNumber, conflictsNumber"
			listConflictsAndFiles.each do |dado|
				file.puts "#{dado}"
			end
		end

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_ConflictingFilesAndConflicts.csv", 'r') do |mainMerges| 
			#while line = mainMerges.gets 
				mainMerges.each_line do |line|
					camposMainMerge = line.split(",")
						File.open(localClone+pathOutput+prefixProjectName+"_CommitList.csv", 'r') do |auxMerges| 
				#			while lineAux = auxMerges.gets 
								auxMerges.each_line do |lineAux|
									camposAuxMerge = lineAux.split(",")
									if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
										mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
										isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
										existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
										totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","")
										conflictingFilesNumber = camposMainMerge[4].gsub("\"","").gsub("\n","")
										conflictsNumber = camposMainMerge[5].gsub("\"","").gsub("\n","")
										numberOfCommitsArithAverage = camposAuxMerge[8].gsub("\"","").gsub("\n","")#8
										numberOfCommitsGeoAverage = camposAuxMerge[9].gsub("\"","").gsub("\n","")#8#9
										dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage
										listNumberOfCommits.push(dados)
									end
								end #each_line
			#				end #while
						end # File.open
				end #each_line
		#	end #while
		end # File.open

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_NumberOfCommits.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices, conflictingFilesNumber, conflictsNumber, numberOfCommitsArithAverage, numberOfCommitsGeoAverage"
			listNumberOfCommits.each do |dado|
				file.puts "#{dado}"
			end
		end


		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_NumberOfCommits.csv", 'r') do |mainMerges| 
			#while line = mainMerges.gets 
				mainMerges.each_line do |line|
					camposMainMerge = line.split(",")
						File.open(localClone+pathOutput+prefixProjectName+"_AuthorList.csv", 'r') do |auxMerges| 
				#			while lineAux = auxMerges.gets 
								auxMerges.each_line do |lineAux|
									camposAuxMerge = lineAux.split(",")
									if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
										mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
										isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
										existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
										totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","")
										conflictingFilesNumber = camposMainMerge[4].gsub("\"","").gsub("\n","")
										conflictsNumber = camposMainMerge[5].gsub("\"","").gsub("\n","")
										numberOfCommitsArithAverage = camposMainMerge[6].gsub("\"","").gsub("\n","")
										numberOfCommitsGeoAverage = camposMainMerge[7].gsub("\"","").gsub("\n","")
										numberOfAuthorsArithAverage = camposAuxMerge[5].gsub("\"","").gsub("\n","")
										numberOfAuthorsGeoAverage = camposAuxMerge[6].gsub("\"","").gsub("\n","")
										
										dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage+","+numberOfAuthorsArithAverage+","+numberOfAuthorsGeoAverage
										listNumberOfAuthors.push(dados)
									end
								end #each_line
			#				end #while
						end # File.open
				end #each_line
		#	end #while
		end # File.open

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_NumberOfAuhtors.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices, conflictingFilesNumber, conflictsNumber, numberOfCommitsArithAverage, numberOfCommitsGeoAverage, numberOfAuthorsArithAverage, numberOfAuthorsGeoAverage"
			listNumberOfAuthors.each do |dado|
				file.puts "#{dado}"
			end
		end
		
		# Deprecated - generate csv with delay and delta integration - metrics not used in the paper - extra evaluation purposes
		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_NumberOfAuhtors.csv", 'r') do |mainMerges| 
			while line = mainMerges.gets
				mainMerges.each_line do |line|
					camposMainMerge = line.split(",")
						File.open(localClone+pathOutput+prefixProjectName+"_DelayDeltaIntegrationList.csv", 'r') do |auxMerges|
							while lineAux = auxMerges.gets
								auxMerges.each_line do |lineAux|
									camposAuxMerge = lineAux.split(",")
									if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
										mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
										isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
										existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
										totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","")
										conflictingFilesNumber = camposMainMerge[4].gsub("\"","").gsub("\n","")
										conflictsNumber = camposMainMerge[5].gsub("\"","").gsub("\n","")
										numberOfCommitsArithAverage = camposMainMerge[6].gsub("\"","").gsub("\n","")
										numberOfCommitsGeoAverage = camposMainMerge[7].gsub("\"","").gsub("\n","")
										numberOfAuthorsArithAverage = camposMainMerge[8].gsub("\"","").gsub("\n","")
										numberOfAuthorsGeoAverage = camposMainMerge[9].gsub("\"","").gsub("\n","")
										delayIntegrationArithAverage = camposAuxMerge[4].gsub("\"","").gsub("\n","")
										delayIntegrationGeoAverage = camposAuxMerge[5].gsub("\"","").gsub("\n","")
										deltaIntegration = camposAuxMerge[6].gsub("\"","").gsub("\n","")
										dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage+","+numberOfAuthorsArithAverage+","+numberOfAuthorsGeoAverage+","+delayIntegrationArithAverage+","+delayIntegrationGeoAverage+","+deltaIntegration
										listDelayDeltaIntegration.push(dados)
									end
								end #each_line
							end #while
						end # File.open
				end #each_line
			end #while
		end # File.open

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_DelayAndDeltaIntegration.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices, conflictingFilesNumber, conflictsNumber, numberOfCommitsArithAverage, numberOfCommitsGeoAverage, numberOfAuthorsArithAverage, numberOfAuthorsGeoAverage, delayIntegrationArithAverage, delayIntegrationGeoAverage, deltaIntegration"
			listDelayDeltaIntegration.each do |dado|
				file.puts "#{dado}"
			end
		end

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_DelayAndDeltaIntegration.csv", 'r') do |mainMerges| 
			while line = mainMerges.gets
				mainMerges.each_line do |line|
					camposMainMerge = line.split(",")
						File.open(localClone+pathOutput+prefixProjectName+"_LifetimeAuthorDateList.csv", 'r') do |auxMerges| 
							while lineAux = auxMerges.gets
								auxMerges.each_line do |lineAux|
									camposAuxMerge = lineAux.split(",")
									if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
										mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
										isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
										existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
										totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","")
										conflictingFilesNumber = camposMainMerge[4].gsub("\"","").gsub("\n","")
										conflictsNumber = camposMainMerge[5].gsub("\"","").gsub("\n","")
										numberOfCommitsArithAverage = camposMainMerge[6].gsub("\"","").gsub("\n","")
										numberOfCommitsGeoAverage = camposMainMerge[7].gsub("\"","").gsub("\n","")
										numberOfAuthorsArithAverage = camposMainMerge[8].gsub("\"","").gsub("\n","")
										numberOfAuthorsGeoAverage = camposMainMerge[9].gsub("\"","").gsub("\n","")
										delayIntegrationArithAverage = camposMainMerge[10].gsub("\"","").gsub("\n","")
										delayIntegrationGeoAverage = camposMainMerge[11].gsub("\"","").gsub("\n","")
										deltaIntegration = camposMainMerge[12].gsub("\"","").gsub("\n","")
										minimumLifeTimeArithAverage = camposAuxMerge[4].gsub("\"","").gsub("\n","")
										minimumLifeTimeGeoAverage = camposAuxMerge[5].gsub("\"","").gsub("\n","")
										dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage+","+numberOfAuthorsArithAverage+","+numberOfAuthorsGeoAverage+","+delayIntegrationArithAverage+","+delayIntegrationGeoAverage+","+deltaIntegration+","+minimumLifeTimeArithAverage+","+minimumLifeTimeGeoAverage
										listMinimumLifeTime.push(dados)
									end
								end #each_line
							end #while
						end # File.open
				end #each_line
			end #while
		end # File.open

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_MinimumLifeTime.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices, conflictingFilesNumber, conflictsNumber, numberOfCommitsArithAverage, numberOfCommitsGeoAverage, numberOfAuthorsArithAverage, numberOfAuthorsGeoAverage, delayIntegrationArithAverage, delayIntegrationGeoAverage, deltaIntegration, minimumLifeTimeArithAverage, minimumLifeTimeGeoAverage"
			listMinimumLifeTime.each do |dado|
				file.puts "#{dado}"
			end
		end

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_MinimumLifeTime.csv", 'r') do |mainMerges| 
			while line = mainMerges.gets
				mainMerges.each_line do |line|
					camposMainMerge = line.split(",")
						File.open(localClone+pathOutput+prefixProjectName+"_NumberOfChangedFiles.csv", 'r') do |auxMerges| 
							while lineAux = auxMerges.gets
								auxMerges.each_line do |lineAux|
									camposAuxMerge = lineAux.split(",")
									if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
										mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
										isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
										existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
										totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","")
										conflictingFilesNumber = camposMainMerge[4].gsub("\"","").gsub("\n","")
										conflictsNumber = camposMainMerge[5].gsub("\"","").gsub("\n","")
										numberOfCommitsArithAverage = camposMainMerge[6].gsub("\"","").gsub("\n","")
										numberOfCommitsGeoAverage = camposMainMerge[7].gsub("\"","").gsub("\n","")
										numberOfAuthorsArithAverage = camposMainMerge[8].gsub("\"","").gsub("\n","")
										numberOfAuthorsGeoAverage = camposMainMerge[9].gsub("\"","").gsub("\n","")
										delayIntegrationArithAverage = camposMainMerge[10].gsub("\"","").gsub("\n","")
										delayIntegrationGeoAverage = camposMainMerge[11].gsub("\"","").gsub("\n","")
										deltaIntegration = camposMainMerge[12].gsub("\"","").gsub("\n","")
										minimumLifeTimeArithAverage = camposMainMerge[13].gsub("\"","").gsub("\n","")
										minimumLifeTimeGeoAverage = camposMainMerge[14].gsub("\"","").gsub("\n","")
										numberOfChangedFilesArithAverage = camposAuxMerge[4].gsub("\"","").gsub("\n","")
										numberOfChangedFilesGeoAverage = camposAuxMerge[5].gsub("\"","").gsub("\n","")
										
										dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage+","+numberOfAuthorsArithAverage+","+numberOfAuthorsGeoAverage+","+delayIntegrationArithAverage+","+delayIntegrationGeoAverage+","+deltaIntegration+","+minimumLifeTimeArithAverage+","+minimumLifeTimeGeoAverage+","+numberOfChangedFilesArithAverage+","+numberOfChangedFilesGeoAverage
										listNmberOfChangedFiles.push(dados)
									end
								end #each_line
							end #while
						end # File.open
				end #each_line
			end #while
		end # File.open

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_NumberOfChangedFiles.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices, conflictingFilesNumber, conflictsNumber, numberOfCommitsArithAverage, numberOfCommitsGeoAverage, numberOfAuthorsArithAverage, numberOfAuthorsGeoAverage, delayIntegrationArithAverage, delayIntegrationGeoAverage, deltaIntegration, minimumLifeTimeArithAverage, minimumLifeTimeGeoAverage, numberOfChangedFilesArithAverage, numberOfChangedFilesGeoAverage"
			listNmberOfChangedFiles.each do |dado|
				file.puts "#{dado}"
			end
		end


		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_NumberOfChangedFiles.csv", 'r') do |mainMerges| 
			while line = mainMerges.gets
				mainMerges.each_line do |line|
					camposMainMerge = line.split(",")
						File.open(localClone+pathOutput+prefixProjectName+"_NumberOfChangedLines.csv", 'r') do |auxMerges| 
							while lineAux = auxMerges.gets
								auxMerges.each_line do |lineAux|
									camposAuxMerge = lineAux.split(",")
									if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
										mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
										isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
										existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
										totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","")
										conflictingFilesNumber = camposMainMerge[4].gsub("\"","").gsub("\n","")
										conflictsNumber = camposMainMerge[5].gsub("\"","").gsub("\n","")
										numberOfCommitsArithAverage = camposMainMerge[6].gsub("\"","").gsub("\n","")
										numberOfCommitsGeoAverage = camposMainMerge[7].gsub("\"","").gsub("\n","")
										numberOfAuthorsArithAverage = camposMainMerge[8].gsub("\"","").gsub("\n","")
										numberOfAuthorsGeoAverage = camposMainMerge[9].gsub("\"","").gsub("\n","")
										delayIntegrationArithAverage = camposMainMerge[10].gsub("\"","").gsub("\n","")
										delayIntegrationGeoAverage = camposMainMerge[11].gsub("\"","").gsub("\n","")
										deltaIntegration = camposMainMerge[12].gsub("\"","").gsub("\n","")
										minimumLifeTimeArithAverage = camposMainMerge[13].gsub("\"","").gsub("\n","")
										minimumLifeTimeGeoAverage = camposMainMerge[14].gsub("\"","").gsub("\n","")
										numberOfChangedFilesArithAverage = camposMainMerge[15].gsub("\"","").gsub("\n","")
										numberOfChangedFilesGeoAverage = camposMainMerge[16].gsub("\"","").gsub("\n","")
										numberOfChangedLinesArithAverage = camposAuxMerge[4].gsub("\"","").gsub("\n","")
										numberOfChangedLinesGeoAverage = camposAuxMerge[5].gsub("\"","").gsub("\n","")
										
										dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage+","+numberOfAuthorsArithAverage+","+numberOfAuthorsGeoAverage+","+delayIntegrationArithAverage+","+delayIntegrationGeoAverage+","+deltaIntegration+","+minimumLifeTimeArithAverage+","+minimumLifeTimeGeoAverage+","+numberOfChangedFilesArithAverage+","+numberOfChangedFilesGeoAverage+","+numberOfChangedLinesArithAverage+","+numberOfChangedLinesGeoAverage
										listNumberOfChangedLines.push(dados)
									end
								end #each_line
							end #while
						end # File.open
				end #each_line
			end #while
		end # File.open

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_NumberOfChangedLines.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices, conflictingFilesNumber, conflictsNumber, numberOfCommitsArithAverage, numberOfCommitsGeoAverage, numberOfAuthorsArithAverage, numberOfAuthorsGeoAverage, delayIntegrationArithAverage, delayIntegrationGeoAverage, deltaIntegration, minimumLifeTimeArithAverage, minimumLifeTimeGeoAverage, numberOfChangedFilesArithAverage, numberOfChangedFilesGeoAverage, numberOfChangedLinesArithAverage, numberOfChangedLinesGeoAverage"
			listNumberOfChangedLines.each do |dado|
				file.puts "#{dado}"
			end
		end

		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_NumberOfChangedLines.csv", 'r') do |mainMerges|
			while line = mainMerges.gets
				mainMerges.each_line do |line|
					camposMainMerge = line.split(",")
					File.open(localClone+pathOutput+prefixProjectName+"_ContributionConclusionDelayList.csv", 'r') do |auxMerges|
						while lineAux = auxMerges.gets
							auxMerges.each_line do |lineAux|
								camposAuxMerge = lineAux.split(",")
								if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
									mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
									isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
									existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
									totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","")
									conflictingFilesNumber = camposMainMerge[4].gsub("\"","").gsub("\n","")
									conflictsNumber = camposMainMerge[5].gsub("\"","").gsub("\n","")
									numberOfCommitsArithAverage = camposMainMerge[6].gsub("\"","").gsub("\n","")
									numberOfCommitsGeoAverage = camposMainMerge[7].gsub("\"","").gsub("\n","")
									numberOfAuthorsArithAverage = camposMainMerge[8].gsub("\"","").gsub("\n","")
									numberOfAuthorsGeoAverage = camposMainMerge[9].gsub("\"","").gsub("\n","")
									delayIntegrationArithAverage = camposMainMerge[10].gsub("\"","").gsub("\n","")
									delayIntegrationGeoAverage = camposMainMerge[11].gsub("\"","").gsub("\n","")
									deltaIntegration = camposMainMerge[12].gsub("\"","").gsub("\n","")
									minimumLifeTimeArithAverage = camposMainMerge[13].gsub("\"","").gsub("\n","")
									minimumLifeTimeGeoAverage = camposMainMerge[14].gsub("\"","").gsub("\n","")
									numberOfChangedFilesArithAverage = camposMainMerge[15].gsub("\"","").gsub("\n","")
									numberOfChangedFilesGeoAverage = camposMainMerge[16].gsub("\"","").gsub("\n","")
									numberOfChangedLinesArithAverage = camposMainMerge[17].gsub("\"","").gsub("\n","")
									numberOfChangedLinesGeoAverage = camposMainMerge[18].gsub("\"","").gsub("\n","")
									contributionConclusionDelay = camposAuxMerge[4].gsub("\"","").gsub("\n","")

									dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage+","+numberOfAuthorsArithAverage+","+numberOfAuthorsGeoAverage+","+delayIntegrationArithAverage+","+delayIntegrationGeoAverage+","+deltaIntegration+","+minimumLifeTimeArithAverage+","+minimumLifeTimeGeoAverage+","+numberOfChangedFilesArithAverage+","+numberOfChangedFilesGeoAverage+","+numberOfChangedLinesArithAverage+","+numberOfChangedLinesGeoAverage+","+contributionConclusionDelay
									listContributionConclusionDelay.push(dados)
								end
							end #each_line
						end #while
					end # File.open
				end #each_line
			end #while
		end # File.open

		#File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_ContributionConclusionDelay.csv", 'w') do |file|
		File.open(localClone+pathOutput+prefixProjectName+"_AllVariables.csv", 'w') do |file|
			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices, conflictingFilesNumber, conflictsNumber, numberOfCommitsArithAverage, numberOfCommitsGeoAverage, numberOfAuthorsArithAverage, numberOfAuthorsGeoAverage, delayIntegrationArithAverage, delayIntegrationGeoAverage, deltaIntegration, minimumLifeTimeArithAverage, minimumLifeTimeGeoAverage, numberOfChangedFilesArithAverage, numberOfChangedFilesGeoAverage, numberOfChangedLinesArithAverage, numberOfChangedLinesGeoAverage, contributionConclusionDelay"
			listContributionConclusionDelay.each do |dado|
				file.puts "#{dado}"
			end
		end

		# Metric do not presented in this paper
#		File.open(localClone+pathOutput+"tmp/"+prefixProjectName+"_ContributionConclusionDelay.csv", 'r') do |mainMerges|
#			while line = mainMerges.gets
#				mainMerges.each_line do |line|
#					camposMainMerge = line.split(",")
#					File.open(localClone+pathInput+prefixProjectName+"_Packages.csv", 'r') do |auxMerges|
#						while lineAux = auxMerges.gets
#							auxMerges.each_line do |lineAux|
#								camposAuxMerge = lineAux.split(",")
#								if camposMainMerge[0].gsub("\"","").eql?(camposAuxMerge[0].gsub("\"",""))
#									mergeCommitID = camposMainMerge[0].gsub("\"","").gsub("\n","")
#									isConflicting = camposMainMerge[1].gsub("\"","").gsub("\n","")
#									existsCommonSlice = camposMainMerge[2].gsub("\"","").gsub("\n","")
#									totalCommonSlices = camposMainMerge[3].gsub("\"","").gsub("\n","").gsub("\r","")
#									conflictingFilesNumber = camposMainMerge[4].gsub("\"","").gsub("\n","")
#									conflictsNumber = camposMainMerge[5].gsub("\"","").gsub("\n","")
#									numberOfCommitsArithAverage = camposMainMerge[6].gsub("\"","").gsub("\n","")
#									numberOfCommitsGeoAverage = camposMainMerge[7].gsub("\"","").gsub("\n","")
#									numberOfAuthorsArithAverage = camposMainMerge[8].gsub("\"","").gsub("\n","")
#									numberOfAuthorsGeoAverage = camposMainMerge[9].gsub("\"","").gsub("\n","")
#									delayIntegrationArithAverage = camposMainMerge[10].gsub("\"","").gsub("\n","")
#									delayIntegrationGeoAverage = camposMainMerge[11].gsub("\"","").gsub("\n","")
#									deltaIntegration = camposMainMerge[12].gsub("\"","").gsub("\n","")
#									minimumLifeTimeArithAverage = camposMainMerge[13].gsub("\"","").gsub("\n","")
#									minimumLifeTimeGeoAverage = camposMainMerge[14].gsub("\"","").gsub("\n","")
#									numberOfChangedFilesArithAverage = camposMainMerge[15].gsub("\"","").gsub("\n","")
#									numberOfChangedFilesGeoAverage = camposMainMerge[16].gsub("\"","").gsub("\n","")
#									numberOfChangedLinesArithAverage = camposMainMerge[17].gsub("\"","").gsub("\n","")
#									numberOfChangedLinesGeoAverage = camposMainMerge[18].gsub("\"","").gsub("\n","")
#									contributionConclusionDelay = camposMainMerge[19].gsub("\"","").gsub("\n","")
#									#metricas de package adicionadas
#									existsCommonPackages = camposAuxMerge[2].gsub("\"","").gsub("\n","")
#									totalCommonPackages = camposAuxMerge[3].gsub("\"","").gsub("\n","").gsub("\r","")
#
#									dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage+","+numberOfAuthorsArithAverage+","+numberOfAuthorsGeoAverage+","+delayIntegrationArithAverage+","+delayIntegrationGeoAverage+","+deltaIntegration+","+minimumLifeTimeArithAverage+","+minimumLifeTimeGeoAverage+","+numberOfChangedFilesArithAverage+","+numberOfChangedFilesGeoAverage+","+numberOfChangedLinesArithAverage+","+numberOfChangedLinesGeoAverage+","+contributionConclusionDelay+","+existsCommonPackages+","+totalCommonPackages
#									listPackages.push(dados)
#									puts "dados = #{dados.dump}"
#								end
#							end #each_line
#						end #while
#					end # File.open
#				end #each_line
#			end #while
#		end # File.open
#
#		File.open(localClone+pathOutput+prefixProjectName+"_AllVariables.csv", 'w') do |file|
#			file.puts "mergeCommitID, isConflicting, existsCommonSlice, totalCommonSlices, conflictingFilesNumber, conflictsNumber, numberOfCommitsArithAverage, numberOfCommitsGeoAverage, numberOfAuthorsArithAverage, numberOfAuthorsGeoAverage, delayIntegrationArithAverage, delayIntegrationGeoAverage, deltaIntegration, minimumLifeTimeArithAverage, minimumLifeTimeGeoAverage, numberOfChangedFilesArithAverage, numberOfChangedFilesGeoAverage, numberOfChangedLinesArithAverage, numberOfChangedLinesGeoAverage, contributionConclusionDelay, existsCommonPackages, totalCommonPackages"
#			listPackages.each do |dado|
#				file.puts "#{dado}"
#				#puts "#{dado}"
#			end
#		end

		puts "end running generateCVSToStatisticAnalysis from #{prefixProjectName} project"
	end # Method declaration
	

	#  Generate a single CSV file (for the aggregated sample.) with all grouped metrics for statistical analysis.
	
	def generateCVSToStatisticAnalysisAggregatedSample(projectName, localClone, pathInput, pathOutput)
	 	prefixProjectName = formatProjectName(projectName)
		projectsList = []
		File.open(localClone+pathOutput+prefixProjectName+"_AllVariables.csv", "r") do |text|
			#indexLine = 0
			text.gets #ler o cabeçalho
			text.each_line do |line|
				lista = line.split(",")

				mergeCommitID = lista[0]
				isConflicting = lista[1]
				existsCommonSlice = lista[2]
				totalCommonSlices = lista[3] # not used in the paper- extra evaluation purposes
				conflictingFilesNumber = lista[4]
				conflictsNumber = lista[5]
				numberOfCommitsArithAverage = lista[6] # not used in the paper- extra evaluation purposes
				numberOfCommitsGeoAverage = lista[7]
				numberOfAuthorsArithAverage = lista[8] # not used in the paper- extra evaluation purposes
				numberOfAuthorsGeoAverage = lista[9]
				delayIntegrationArithAverage = lista[10] # not used in the paper- extra evaluation purposes
				delayIntegrationGeoAverage = lista[11] # not used in the paper- extra evaluation purposes
				deltaIntegration = lista[12] # not used in the paper- extra evaluation purposes
				minimumLifeTimeArithAverage = lista[13] # not used in the paper- extra evaluation purposes
				minimumLifeTimeGeoAverage = lista[14]
				numberOfChangedFilesArithAverage = lista[15] # not used in the paper- extra evaluation purposes
				numberOfChangedFilesGeoAverage = lista[16]
				numberOfChangedLinesArithAverage = lista[17] # not used in the paper- extra evaluation purposes
				numberOfChangedLinesGeoAverage = lista[18]
				contributionConclusionDelay = lista[19]
				#existsCommonPackages = lista[20] # not used in the paper- extra evaluation purposes
				#totalCommonPackages = lista[21] # not used in the paper- extra evaluation purposes

				mergeCommitID = lista[0].gsub("\r","").gsub("\n","")

				#dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage+","+numberOfAuthorsArithAverage+","+numberOfAuthorsGeoAverage+","+delayIntegrationArithAverage+","+delayIntegrationGeoAverage+","+deltaIntegration+","+minimumLifeTimeArithAverage+","+minimumLifeTimeGeoAverage+","+numberOfChangedFilesArithAverage+","+numberOfChangedFilesGeoAverage+","+numberOfChangedLinesArithAverage+","+numberOfChangedLinesGeoAverage+","+contributionConclusionDelay+","+existsCommonPackages+","+totalCommonPackages
				dados = mergeCommitID+","+isConflicting+","+existsCommonSlice+","+totalCommonSlices+","+conflictingFilesNumber+","+conflictsNumber+","+numberOfCommitsArithAverage+","+numberOfCommitsGeoAverage+","+numberOfAuthorsArithAverage+","+numberOfAuthorsGeoAverage+","+delayIntegrationArithAverage+","+delayIntegrationGeoAverage+","+deltaIntegration+","+minimumLifeTimeArithAverage+","+minimumLifeTimeGeoAverage+","+numberOfChangedFilesArithAverage+","+numberOfChangedFilesGeoAverage+","+numberOfChangedLinesArithAverage+","+numberOfChangedLinesGeoAverage+","+contributionConclusionDelay
				projectsList.push(dados.gsub("\n", ""))
			end
		end

		 File.open(localClone+pathOutput+"allProjects_AllVariables.csv", 'a') do |file|
			 if (File.size(localClone+pathOutput+"allProjects_AllVariables.csv") == 0)
				 #file.puts "mergeCommitID,isConflicting,existsCommonSlice,totalCommonSlices,conflictingFilesNumber,conflictsNumber,numberOfCommitsArithAverage,numberOfCommitsGeoAverage,numberOfAuthorsArithAverage,numberOfAuthorsGeoAverage,delayIntegrationArithAverage,delayIntegrationGeoAverage,deltaIntegration,minimumLifeTimeArithAverage,minimumLifeTimeGeoAverage,numberOfChangedFilesArithAverage,numberOfChangedFilesGeoAverage,numberOfChangedLinesArithAverage,numberOfChangedLinesGeoAverage,contributionConclusionDelay,existsCommonPackages,totalCommonPackages"
				 file.puts "mergeCommitID,isConflicting,existsCommonSlice,totalCommonSlices,conflictingFilesNumber,conflictsNumber,numberOfCommitsArithAverage,numberOfCommitsGeoAverage,numberOfAuthorsArithAverage,numberOfAuthorsGeoAverage,delayIntegrationArithAverage,delayIntegrationGeoAverage,deltaIntegration,minimumLifeTimeArithAverage,minimumLifeTimeGeoAverage,numberOfChangedFilesArithAverage,numberOfChangedFilesGeoAverage,numberOfChangedLinesArithAverage,numberOfChangedLinesGeoAverage,contributionConclusionDelay"
			 end

			 projectsList.each do |dado|
				file.puts "#{dado}"
			end
		 end

		puts "end running generateCVSToStatisticAnalysisAggregatedSample from #{prefixProjectName} project"
	end


end
