require_cocoa "UIColor"
require_cocoa "UIView"
require_cocoa "UIImage"
require_cocoa "UIImageView"
require_cocoa "UILabel"
require_cocoa "UIFont"
require_cocoa "UIButton"
require_cocoa "UIAlertController"
require_cocoa "UIAlertAction"

def create_view(super_view)
    # Clolors
    red = UIColor.redColor
    blue = UIColor.blueColor
    green = UIColor.greenColor
    yellow = UIColor.yellowColor
    white = UIColor.whiteColor
    
    super_view.setBackgroundColor_(white)
    
    # UIlabel
    super_view.addSubview_(createLabel("UILabel", 40, 64))
    
    label = UILabel.alloc.init
    label.setFrame_({'x' => 200, 'y' => 64, 'width' => 150, 'height' => 50})
    label.setText_("Hello World!")
    label.setFont_(UIFont.systemFontOfSize_(24))
    label.setTextColor_(red)
    label.setBackgroundColor_(green)
    super_view.addSubview_(label)
    
    # UIView
    super_view.addSubview_(createLabel("UIView", 40, 120))
    
    blue_sub_view = UIView.alloc.init
    blue_sub_view.setFrame_({'x' => 200, 'y' => 120, 'width' => 100, 'height' => 100})
    blue_sub_view.setBackgroundColor_(blue)
    super_view.addSubview_(blue_sub_view)
    
    # UIImageView
    super_view.addSubview_(createLabel("UIImageView", 40, 230))
    
    image = UIImage.imageNamed_("logo")
    image_view = UIImageView.alloc.initWithImage_(image)
    image_view.setFrame_({'x'=>200, 'y'=> 230, 'width' => 100, 'height' => 100})
    super_view.addSubview_(image_view)
    
    # UIButton
    super_view.addSubview_(createLabel("UIButton", 40, 340))

    btn = UIButton.buttonWithType_(0)
    ## MRBCocoa::Const::Target is defined in OC
    ## [self.context registerConst:@"Target" value:self];
    ## “self” is the view controller
    ## "touchAction:" action is defined in OC and execute ruby script to show alert
    btn.addTarget_action_forControlEvents_(MRBCocoa::Const::Target, "touchAction:", 1<<6)
    btn.setTitle_forState_("Click to show alert", 0)
    btn.setFrame_({'x' => 200, 'y' => 340, 'width' => 170, 'height' => 50})
    btn.setBackgroundColor_(red)
    super_view.addSubview_(btn)
end

def showAlertView
    # UIAlertController
    completion = Proc.new {puts "show..."}
    completion_block = completion.to_cocoa_block("void,void")
    alertController = UIAlertController.alertControllerWithTitle_message_preferredStyle_("iMRuby", "Hello World!", 1)
    
    ok_handler = Proc.new {|action| puts "OK..."}
    ok_handler_block = ok_handler.to_cocoa_block("void, UIAlertAction")
    okAction = UIAlertAction.actionWithTitle_style_handler_("OK", 0, ok_handler_block)
    
    alertController.addAction_(okAction)
    
    MRBCocoa::Const::Target.presentViewController_animated_completion_(alertController, true, completion_block)
end

def createLabel(text, x, y)
    label = UILabel.alloc.init
    label.setFrame_({'x' => x, 'y' => y, 'width' => 150, 'height' => 50})
    label.setText_(text)
    label.setFont_(UIFont.systemFontOfSize_(24))
    label.setTextColor_(UIColor.blackColor)
    return label
end
