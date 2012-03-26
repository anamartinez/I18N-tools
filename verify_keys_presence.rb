### How to run ###
#
# 1. In console run: ruby verify_keys_presence <directory> <options>
# 2. If you only want to find the missing txt.admin keys use option -a. This will only store keys in admin.yml
# 3. If you want to load the whitelist file use option -w
#
##################

def run_find_missing_keys
  @key_hash = Hash.new
  @missing_keys = Array.new
  @white_list = Hash.new
  get_args
  get_files_directory(@file_to_check)
  check_missing_keys
end

def get_args
  if ARGV.include? "-a"
    path_yml_file = "zendesk/config/locales/translations/admin.yml"
    read_yml_file(path_yml_file)
    @only_show_admin_keys = true
  else
    path_yml_file = "zendesk/config/locales/translations/"
    get_all_yml_files(path_yml_file)
  end
  
  if ARGV.include? "-w"
    get_while_list_keys("whitelist")
  end
  
  @file_to_check = ARGV[0]
end

def read_yml_file(path)
  File.open(path).each { |line|
    line = line.strip
    if line.start_with?("key")
      key = eliminate_unnecessary_chars(line)
      @key_hash[key] = 0
    end
  }
end

def eliminate_unnecessary_chars(line)
  line = line.slice(4, line.length).slice(0..-2)  #Eliminates "key:" string and '"' string. 
  line = line.strip                               #Eliminates spaces before after key string and before key
  line = line.slice(1, line.length)               #Eliminates '"' at the beginning of the key
  return line
end

def get_all_yml_files(path)
  if File.directory?(path)
    Dir.foreach(path) {|x| 
      if !(x == "." || x == ".." || x == ".DS_Store")
        if File.directory?(path + x)
          get_all_yml_files(path + x)
        else
          read_yml_file(path + x)
        end
      end
      }
  else
    read_yml_file(path + x)
  end
end

def get_while_list_keys(path)
  File.open(path).each { |line|
    line = line.strip
    @white_list[line] = 0
  }
end

def get_files_directory (path)
  if File.directory?(path)
    Dir.foreach(path) {|x| 
      if !(x == "." || x == "..")
        if File.directory?(path + "/" + x)
          get_files_directory(path + "/" + x)
        else
          go_through_files(path + "/" + x)
        end
      end
      }
  else
    go_through_files(path)
  end
end

def go_through_files(directory)
  File.open(directory).each{ |line|
    if line.index("I18n.t(")
      line = line.strip
      prepare_line(line)
    elsif line.index("I18n[")
      line = line.strip
      prepate_line_javascript(line)
    end
  }
end

def prepare_line(line)
  begin
    line = line.slice(line.index('I18n.t('), line.length)
    character = line[7].chr
    line = line.slice(8, line.length)
    key = get_key(line, character)
    if key != nil && key.index('txt.') == 0
      check_in_yml(key)
    end
  end while line.index('I18n.t(') != nil
end

def prepate_line_javascript(line)
  begin
    line = line.slice(line.index('I18n['), line.length)
    character = line[5].chr
    line = line.slice(6, line.length)
    key = get_key(line, character)
    if key != nil && key.index('txt.') == 0
      check_in_yml(key)
    end
  end while line.index('I18n[') != nil
end

def get_key(line, character)
  if line.index(character) != nil
    return line.slice!(0, line.index(character))
  end
end

def check_in_yml (key)
  if !@key_hash.has_key?(key) && !@white_list.has_key?(key) && !@missing_keys.include?(key)
    if @only_show_admin_keys && get_only_admin_keys(key)
      @missing_keys.push(key)
    elsif !@only_show_admin_keys
      @missing_keys.push(key)
    end 
  end
end


def get_only_admin_keys(key)
  if key.index("txt.admin.")
    return true	
  end
 	return false	
end

def check_missing_keys
  if @missing_keys.empty?
    puts "No missing keys"
  else
    @missing_keys.each do |key|
      if @white_list.empty?
        puts key
      elsif !@white_list.has_key?(key)
        puts key
      end
    end
  end
end

run_find_missing_keys