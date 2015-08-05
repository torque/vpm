#!/usr/bin/env ruby

# In order to bundle libraries properly, the easiest method is, if the
# main binary is linked with an rpath during compilation to:

# Set all of the linked libraries in the executable to @rpath/library.dylib
# For dependencies of the linked libraries, set them to be @loader_path/library.dylib.

# class Library

class OSXBundle

	SystemLibDirs   = /^(\/System\/Library|\/usr\/lib)/
	# https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/dyld.1.html
	# The default DYLD_FALLBACK_LIBRARY_PATH is $(HOME)/lib:/usr/local/lib:/lib:/usr/lib.

	# If a linked library is not found by its install name it is searched
	# for in the paths in DYLD_FALLBACK_LIBRARY_PATH.
	DefaultLibPaths = ENV['DYLD_FALLBACK_LIBRARY_PATH']? ENV['DYLD_FALLBACK_LIBRARY_PATH'].split(':'): ["#{ENV['HOME']}/lib", "/usr/local/lib", "/lib", "/usr/lib",]

	def initialize( path, name, contents = { :extralibs => [ ], :extralpaths => [ ] } )
		bundlePath      = "#{path}/#{name}.app"
		@libSearchPaths = DefaultLibPaths + (contents[:extralpaths] || [ ])
		@baseAppDir     = "#{bundlePath}/Contents"
		@executables    = [ name ]
		@exeDirectory   = "#{@baseAppDir}/MacOS"
		@libDirectory   = "#{@baseAppDir}/Frameworks"
		@resourceDir    = "#{@baseAppDir}/Resources"
		ensureDirExists @exeDirectory
		ensureDirExists @libDirectory
		ensureDirExists @resourceDir
		# @masterLibList is a hash that contains all of the encountered
		# libraries, mapped to their fixed paths. It is used for copying all
		# necessary libraries into @libDirectory
		@masterLibList  = { }
		# libtree is a hash that maps each non-system dependency to all of
		# its non-system dependencies.
		@libTree        = { }
		# coalesce install_name_tool changes into singular commands using a
		# dictionary that maps target library names to a string.
		@changesToMake  = { }

		(contents[:extralibs] || [ ]).each do |lib|
			@masterLibList[lib] = File.exist?( lib )? lib: fixLib( lib )
			collectLibs lib
		end
	end

	def ensureDirExists( directory )
		`mkdir -p "#{directory}"`
	end

	def fixLib( lib )
		filename = File.basename lib
		errMessage = "Could not find library #{lib}. Searched the following paths:\n"
		@libSearchPaths.each do |path|
			fullLibPath = "#{path}/#{filename}"
			errMessage += "-> #{fullLibPath}\n"
			if File.exist? fullLibPath
				return fullLibPath
			end
		end
		# Exit with an error here because a required library apparently does not
		# exist, which means the application can't be bundled correctly.
		print errMessage
		exit 1
	end

	def commitLinkPathChanges
		@changesToMake.each do |targetName, command|
			`install_name_tool #{command} "#{targetName}"`
			puts "install_name_tool #{command} \"#{targetName}\""
		end
	end

	def setLibraryLinkPath( library, oldLinkPath, newLinkPath )
		unless @changesToMake[library]
			@changesToMake[library] = ""
		end

		# puts "\"#{library}\": \"#{oldLinkPath}\"=>\"#{newLinkPath}\""
		@changesToMake[library] += " -change \"#{oldLinkPath}\" \"#{newLinkPath}\""
	end

	def setLinkPathToRpath( library, oldLinkPath )
		libraryName = File.basename oldLinkPath
		setLibraryLinkPath library, oldLinkPath, "@rpath/#{libraryName}"
	end

	def setLinkPathToLoaderPath( library, oldLinkPath )
		libraryName = File.basename oldLinkPath
		setLibraryLinkPath library, oldLinkPath, "@loader_path/#{libraryName}"
	end

	def collectLibs( exe )
		# Need to fix exe name because collectLibs will be called with a broken
		# library name if one exists. Sed strips off the first line, and awk strips
		# the leading tab and version information.
		linkedLibs = `otool -LX #{File.exist?( exe )? exe: fixLib( exe )} | sed '1d' | awk '{print $1}'`
		unless @libTree[exe] || linkedLibs == ""
			@libTree[exe] = []
			lines = linkedLibs.split( /\n/ )
			lines.each do |lib|
				fixedLib = lib
				unless File.exist? lib
					fixedLib = fixLib lib
				end
				# `otool -L` lists the library identification name at the top, so we
				# have to make sure we don't end up recursing infinitely. The library
				# basename should include version numbers and be unique.
				if File.basename( lib ) == File.basename( exe )
					puts "WARNING: #{exe} is linked to itself, expect bad results."
				elsif !lib.match( SystemLibDirs )
					# The library needs to be added to libTree even if it's been
					# seen before.
					@libTree[exe] << lib
					unless @masterLibList[lib]
						@masterLibList[lib] = fixedLib
					end
				end
			end
			@libTree[exe].each do |lib|
				collectLibs( lib )
			end
		end
	end

	def fixExeLinks
		@executables.each do |exe|
			exe = "#{@exeDirectory}/#{File.basename exe}"
			collectLibs( exe )
			if @libTree[exe] != nil
				@libTree[exe].each do |lib|
					setLinkPathToRpath exe, lib
				end
			end
		end
	end

	def copyLibrary( libraryName )
		baseName = File.basename libraryName
		destName = "#{@libDirectory}/#{baseName}"
		# puts "Copy: \"#{libraryName}\" => \"#{destName}\""
		`cp "#{libraryName}" "#{destName}"`
		`chmod 755 "#{destName}"`
		`install_name_tool -id "@loader_path/#{baseName}" "#{destName}"`
	end

	def copyLibs
		@masterLibList.each_value do |fixedLib|
			copyLibrary fixedLib
		end
	end

	def fixLibLinks
		copyLibs
		@masterLibList.each_key do |lib|
			libraryName = "#{@libDirectory}/#{File.basename lib}"
			@libTree[lib].each do |childLib|
				setLinkPathToLoaderPath libraryName, childLib
			end
		end
	end

	def bundle
		fixExeLinks
		fixLibLinks
		commitLinkPathChanges
	end
end

vpm = OSXBundle.new ARGV[0], ARGV[1]
vpm.bundle
