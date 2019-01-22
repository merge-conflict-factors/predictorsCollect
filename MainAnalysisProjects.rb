require 'require_all'
require_all './Repository'

class MainAnalysisProjects

	def initialize(loginUser, passwordUser, pathInput, pathOutput, projectsList)
		@loginUser = loginUser
		@passwordUser = passwordUser
		@pathInput = pathInput
		@pathOutput = pathOutput
		@localClone = Dir.pwd #na verdade é localProject raiz para as pastas
		Dir.chdir getLocalCLone
		@projectsList = projectsList
	end
	
	

	def getLocalCLone()
		@localClone
	end

	def getLoginUser()
		@loginUser
	end

	def getPasswordUser()
		@passwordUser
	end


	def getPathInput()
		@pathInput
	end

	
	def getPathOutput()
		@pathOutput
	end
	
	def getProjectsList()
		@projectsList
	end

	def printStartAnalysis()
		puts "*************************************"
		puts "-------------------------------------"
		puts "####### START #######"
		puts "-------------------------------------"
		puts "*************************************"
	end

	def printProjectInformation (index, project)
		puts "Project [#{index}]: #{project}"
	end

	def printFinishAnalysis()
		puts "*************************************"
		puts "-------------------------------------"
		puts "####### FINISH #######"
		puts "-------------------------------------"
		puts "*************************************"
	end

	def runPredictorsAnalysis()
		printStartAnalysis()
		index = 1
		@projectsList.each do |project|
			printProjectInformation(index, project)
			mainGitProject = GitProject.new(project, getLocalCLone(), getLoginUser(), getPasswordUser())
				projectName = mainGitProject.getProjectName()
				puts "projectName = #{projectName}"		#debugging... 
			 	mainGitProject.generateCommitsNumberByMergeScenario(projectName, getLocalCLone(), getPathInput, getPathOutput)
				mainGitProject.generateAuthorsNumberByMergeScenario(projectName, getLocalCLone(), getPathOutput)
				mainGitProject.generateDelayToIntegrationByMergeScenario(projectName, getLocalCLone(), getPathOutput)
			  mainGitProject.generateContributionConclusionDelayByMergeScenario(projectName, getLocalCLone(), getPathOutput)
				mainGitProject.generateLifetimeContributionByMergeScenario(projectName, getLocalCLone(), getPathOutput)
			 	mainGitProject.getNumberOfChangedFilesAndChangedLines(projectName, getLocalCLone(), getPathInput, getPathOutput)
				mainGitProject.generateCVSToStatisticAnalysis(projectName, getLocalCLone(), getPathInput, getPathOutput)
				mainGitProject.generateCVSToStatisticAnalysisAggregatedSample(projectName, getLocalCLone(), getPathInput, getPathOutput)

				mainGitProject.deleteProject()
			index += 1
		end
		printFinishAnalysis()
	end

end

parameters = []
File.open("properties", "r") do |text|
	indexLine = 0
	text.each_line do |line|
		parameters[indexLine] = line[/\<(.*?)\>/, 1]
		indexLine += 1
	end
end

projectsList = []
File.open("projectsList", "r") do |text|
	indexLine = 0
	text.each_line do |line|
		projectsList[indexLine] = line[/\"(.*?)\"/, 1]
		indexLine += 1
	end
end

actualPath = Dir.pwd
project = MainAnalysisProjects.new(parameters[0], parameters[1], parameters[2], parameters[3],projectsList)

#debugging...
puts "Project List[#{project.getProjectsList()}]"
puts "Local Project[#{project.getLocalCLone()}]"
puts "Login User[#{project.getLoginUser()}]"
puts "Password User[#{project.getPasswordUser()}]"
puts "Path Input[#{project.getPathInput()}]"
puts "Path Output[#{project.getPathOutput}]"
# end debugging...


project.runPredictorsAnalysis()


