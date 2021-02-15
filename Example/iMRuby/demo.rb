require_cocoa 'Person'

person = Person.alloc.init
person.setName_('anan')
person.setAge_(2)
message = person.__say__something_("happy Niu year!")
puts message

finished = Proc.new {|name, age| puts "I am #{name}, #{age} year old"; true}
finished_block = finished.to_cocoa_block("BOOL, NSString *, int");
person.coding_finished_("Ruby", finished_block)
