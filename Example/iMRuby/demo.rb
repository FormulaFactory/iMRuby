require_cocoa 'Person'
require_cocoa 'NSObject'

person = Person.alloc.init
person.setName_('anan')
person.setAge_(2)
message = person.__say__something_("happy Niu year!")
puts message

finished = Proc.new {|name, age| "I am #{name}, #{age} years old" };
finished_block = finished.to_cocoa_block("NSString *, NSString *, int");
str = person.finished_(finished_block)
puts str
