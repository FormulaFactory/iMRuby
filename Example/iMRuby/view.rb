require_cocoa "UIColor"
require_cocoa "UIView"

def create_view(super_view)
    red = UIColor.redColor;
    blue = UIColor.blueColor;
    green = UIColor.greenColor;
    
    super_view.setBackgroundColor_(red)
    
    blue_sub_view = UIView.alloc.init
    blue_sub_view.setFrame_({'x' => 40, 'y' => 200, 'width' => 100, 'height' => 100})
    blue_sub_view.setBackgroundColor_(blue)
    super_view.addSubview_(blue_sub_view)
    
    green_sub_view = UIView.alloc.init
    green_sub_view.setFrame_({'x' => 180, 'y' => 200, 'width' => 100, 'height' => 100})
    green_sub_view.setBackgroundColor_(green)
    super_view.addSubview_(green_sub_view)
end
