module MRBCocoa
    # oc register method in MRBCocoa
    def self.method_missing(method_name, *args)
        self.register_func_call(method_name, *args)
    end
    
    class Block
        # call method will be defined by c api 
        # def call;;end
    end
    
    class Klass
        def method_missing(method_name, *args)
            cocoa_sel = MRBCocoa::PrivateFunc.convert_cocoa_sel(method_name)
            cocoa_export_method(cocoa_sel, *args)
        end
    end
    
    class Object
        def method_missing(method_name, *args)
            cocoa_sel = MRBCocoa::PrivateFunc.convert_cocoa_sel(method_name)
            cocoa_export_method(cocoa_sel, *args)
        end
    end
    
#    module Func
#        def self.method_missing(method_name, *args)
#            self.register_func_call(method_name, *args)
#        end
#    end
    
    module Const
        
    end
    
    module PrivateFunc
        def self.convert_cocoa_sel(method_name)
            method_name_str = method_name.to_s
            fragments = method_name_str.split("_")
            cocoa_sel = ""
            fragments.each_with_index do |f, i|
                if f == ""
                   cocoa_sel += '_'
                else
                    cocoa_sel += f
                    if i+1 < fragments.count && fragments[i+1] != ""
                        cocoa_sel += ':'
                    end
                end
            end
            if method_name_str[method_name_str.length-1] == '_'
                cocoa_sel += ':'
            end
            cocoa_sel
        end
    end
end
