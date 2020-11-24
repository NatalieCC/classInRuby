require 'date'
require "resolv"

class Formatter

  attr_reader :result

    def initialize(input)
        @result = input
    end

    def self.format(str1,str2)
        if str1=="phone_number"
            if str2.include?(':')   #since the input might contains chars, should split by ":"
                str2 = str2.split(' ')  
                return convert_number(str2[1]) if str2.length == 2     #format with just periods or numbers
                    
                res = ""    #deal with patterns such as W: (111) 222 3333 ext 44 #["W:", "(111)", "222", "3333", "ext", "44"]
                i=1
                while i < str2.length
                    curr = str2[i]
                    if curr.include?("(")
                        res.concat(remove_parentheses(curr) ,"-")
                    elsif curr == "ext"
                        res[-1]= 'x'
                    elsif i != str2.length-1
                        res.concat(curr,"-")
                    else
                        res.concat(curr)
                    end
                    i+=1
                end
                return self.new(res)   
            else    #input contains only intergers
                convert_number(str2)
            end
        else    #str1=="date"
            if str2.include?(" ") && str2.match(/^[[:alpha:][:blank:]]+$/)  #check if only contains letters and spaces
                self.new(str2)
            elsif str2.length ==5
                self.new("2020-"+str2[0..1]+"-"+str2[3..4])    #default to current year
            elsif str2.include?("/")
                str2 = str2.split("/") 
                month,day,year = str2[0].to_s, str2[1].to_s, str2[2].to_s
                return self.new(str.join("/")) if month.to_i > 12 || day.to_i > 31 #invalid month or day input
                to_format(year,month,day)
            else
                str2=str2.split('-')
                year,month,day = str2[0].to_s, str2[1].to_s, str2[2].to_s 
                return self.new(str.join("-")) if month.to_i > 12 || day.to_i > 31 #ex: "2000-99-99" => "2000-99-99"
                to_format(year,month,day)
            end 
        end
    end

    private
    def self.remove_parentheses(str)
        res=""
        i=0
        while i<str.length
            res += str[i] if str[i]!="(" && str[i]!=")"
            i+=1
        end
        res
    end

    def self.convert_number(str)
        len = str.length
        num = str.dup
        if (len < 7) || (len>7 && len<10)  #if length <=6 return the input string due to unformattable #so what if it's 8,9?(assumed unformattable)
            return self.new(str)
        elsif len == 10   #if length ==10, insert - at index 3 and 7
            return self.new(num.insert(3,'-').insert(7,'-'))
        elsif len > 10    #if length >10
            if str.include?('.')  #if containing "."
                num[3]="-"
                num[7]="-"
                return self.new(num)
            else 
                num.insert(3,'-').insert(7,'-')
                return self.new(num.insert(12,'x')) #insert 'x' for extension
            end
        elsif len == 7   
            return self.new(num.insert(3,'-'))
        end
    end

    def self.to_format(year,month,day)
        res=""
        if year.length != 4     #check year
            year.to_i > 20 ? res.concat("19",year,"-") : res.concat("20",year,"-") 
            # unsure if a future year would be valid in this case?, set to return past year.
        else
            res.concat(year,"-")
        end
        #check month
        month.length != 2 ? res.concat("0",month,"-") : res.concat(month,"-") 
        #check day 
        day.length != 2 ? res.concat("0",day) : res += day      
        self.new(res)  #return a class instance here to call the instance method written below(.result)
    end
end

puts
puts "#############################"
puts "# format phone_number tests #"
puts "#############################"
{
  "1112223333"               => "111-222-3333",
  "111222333344444"          => "111-222-3333x44444",
  "2223333"                  => "222-3333",
  "223333"                   => "223333", # unformattable

  "Cell: 223333"             => "223333", # unformattable
  "Cell: 111.222.3333"       => "111-222-3333",
   "W: (111) 222 3333 ext 44" => "111-222-3333x44",
}.each do |unformatted_phone_number, expected_result|
  formatted_phone_number = Formatter.format("phone_number", unformatted_phone_number).result
  if formatted_phone_number == expected_result
    puts "PASS - #{unformatted_phone_number.inspect} became #{expected_result.inspect}"
  else
    puts "FAIL - #{unformatted_phone_number.inspect} should be #{expected_result.inspect} but was #{formatted_phone_number.inspect}"
  end
end

puts
puts "#####################"
puts "# format date tests #"
puts "#####################"
{
  "05/30/08"   => Date.new(2008, 5, 30),
  "5/30/09"    => Date.new(2009, 5, 30),
  "05/30/10"   => Date.new(2010, 5, 30),
  "5/30/11"    => Date.new(2011, 5, 30),
  "05/30/2012" => Date.new(2012, 5, 30),
  "5/30/2013"  => Date.new(2013, 5, 30),

  "2014-05-30" => Date.new(2014, 5, 30),
  "2015-5-30"  => Date.new(2015, 5, 30),

  Date.today.strftime("%-m-%-d") => Date.today, # default to current year
  Date.today.strftime("%-m/%-d") => Date.today, # default to current year
  "not a date" => "not a date",
}.each do |unformatted_date, expected_result|
  convert_date_to_s_proc = -> (value) { value.is_a?(Date) ? value.to_s : value }
  expected_result = convert_date_to_s_proc.call(expected_result)
  unformatted_date = convert_date_to_s_proc.call(unformatted_date)
  formatted_date = Formatter.format("date", unformatted_date).result
  formatted_date = convert_date_to_s_proc.call(formatted_date)
  if formatted_date == expected_result
    puts "PASS - #{unformatted_date.inspect} became #{expected_result.inspect}"
  else
    puts "FAIL - #{unformatted_date.inspect} should be #{expected_result.inspect} but was #{formatted_date.inspect}"
  end
end


class EmailAddress
  # Your code here for challenge 3
  def initialize(input)
    @input = input
  end
  
  def valid?
    input= @input.split("@")
    return false if input.length != 2
    username = input[0]
    domain = input[1]
    return check_username(username) && check_domain(domain)
  end

  private
  def check_username(username)
    allowedBeginEnd = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a   #initiate an alphanumeric array
    allowed = allowedBeginEnd +["-","."]                                
    if !allowedBeginEnd.include?(username[0]) || !allowedBeginEnd.include?(username[-1]) 
        return false
    end

    i=1
    while i < username.length-1
        if !allowed.include?(username[i])
            return false
        end
        i+=1
    end
    true
  end

  def check_domain(domain)
    allowed = "abcdefghijklmnopqrstuvwxyz."
    i=0
    while i< domain.length
        return false if !allowed.include?(domain[i])
        i+=1
    end
    return true
  end

end

puts
puts "################################"
puts "# validate email address tests #"
puts "################################"
{
  # valid usernames
  "username@gmail.com"        => true,
  "u.s.e.r.n.a.m.e@gmail.com" => true,
  "us-er.na-me@gmail.com"     => true,
  # invalid usernames
  "username-@gmail.com" => false,
  "username.@gmail.com" => false,
  "-username@gmail.com" => false,
  ".username@gmail.com" => false,
  "user!name@gmail.com" => false,
  # invalid domains
  "username@gmail.com@gmail.com" => false,
  "username@domain-without-dns-mx.com" => false,
}.each do |test_email_address, expected_result|
  email_address = EmailAddress.new(test_email_address)
  actual_result = email_address.valid?
  if actual_result == expected_result
    puts "PASS - #{test_email_address.inspect} should be a #{expected_result ? "valid" : "invalid"} email"
  elsif actual_result == !expected_result
    puts "FAIL - #{test_email_address.inspect} should be a #{expected_result ? "valid" : "invalid"} email"
  else
    puts "FAIL - #{test_email_address.inspect} should be a #{expected_result ? "valid" : "invalid"} email but did not get a boolean result (#{actual_result.inspect})"
  end
end