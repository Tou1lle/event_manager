require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "time"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts(form_letter)
  end
end

def clean_phone_number(phone_number)
  phone_number = phone_number.scan(/\d+/).join("")
  invalid_number = "Invalid number"

  unless phone_number.length == 10
    return (phone_number.length == 11 && phone_number[0] == "1") ? phone_number.slice(1, 10) : invalid_number
  end

  phone_number
end

def open_cvs
  CSV.open(
    "event_attendees.csv",
    headers: true,
    header_converters: :symbol
  )
end

def most_frequent_hour
  content = open_cvs()
  reg_hours = []

  content.each do |row|
    reg_date = row[:regdate]
    reg_hour = Time.strptime(reg_date, "%m/%d/%y %k:%M").strftime("%k")
    reg_hours.push(reg_hour)
  end

  reg_hash = reg_hours.reduce(Hash.new(0)) do | result, hour |
    result[hour] += 1
    result
  end

  max_frequency = reg_hash.values.max
  reg_hash.select do | hour, frequency|
    frequency == max_frequency
  end.keys.join(" and ")
end

puts "Event Manager Initialized!"

contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new(template_letter)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  #zipcode = clean_zipcode(row[:zipcode])
  #legislators = legislators_by_zipcode(zipcode)
  phone_number = row[:homephone]

  # map the string to contain only numbers
  # check if length is 10
  # check if length is 11
  # check if starts if 1
  clean_phone_number = clean_phone_number(phone_number)

  print "Clean phone number: "
  puts clean_phone_number
  print "Bad phone number: "
  puts phone_number

  # get the date and time from contents
  reg_date = row[:regdate]
  reg_hour = Time.strptime(reg_date, "%m/%d/%y %k:%M").strftime("%k")
  reg_day = Time.strptime(reg_date, "%m/%d/%y %k:%M").strftime("%A")

  print "Registration day: "
  puts reg_day
  print "Registration hour: "
  puts reg_hour
  print "Registration date: "
  puts reg_date
  puts "--------------------------"

  #form_letter = erb_template.result(binding)

  #save_thank_you_letter(id, form_letter)
end

most_frequent_hour = most_frequent_hour()
print "Most frequent hour: "
puts most_frequent_hour