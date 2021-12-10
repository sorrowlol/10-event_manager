require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(number)
  number = number.to_s
  number.gsub!(/\D/,'')
  if number.length == 10
    number
  elsif number.length == 11 && number[0] == '1'
    number[1..-1]
  else
    "Bad number"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours_arr = []
hours_hash = {}

days_arr = []
days_hash = {}


contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  hour = row[:regdate][-5..-4]
  week_day = row[:regdate].split(' ')[0]

  #most popular hour
  hours_arr.push(hour)
  hours_hash[hour] = hours_arr.count(hour)

  #most popular day
  days_arr.push(week_day)
  days_hash[week_day] = days_arr.count(week_day)


  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

end

fav_hour = hours_hash.index(hours_hash.values.max)
fav_day = Date.parse(days_hash.index(days_hash.values.max)).strftime("%A")

puts "The best hour is #{fav_hour}"
puts "The best day is #{fav_day}"
