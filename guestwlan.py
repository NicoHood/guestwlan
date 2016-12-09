#!/usr/bin/env python3

# Import Modules
import configparser
from glob import glob 				#search folders
from os.path import join 			#concatenating strings
from kivy.app import App
from kivy.core.window import Window #creating the default Kivy window
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.uix.image import Image 	#Image widget is used to display an image
from kivy.properties import ObjectProperty, StringProperty
from kivy.uix.widget import Widget
from kivy.clock import Clock 		#allows you to schedule a function call in the future
import sys

# TODO does not work
from kivy.uix.carousel import Carousel

# Additional logging information
#from kivy.logger import Logger

# Use Raspberry Pi touch screen if available
from kivy.config import Config
Config.set('input', 'mtdev', 'probesysfs,provider=mtdev')
Config.set('input', 'hid', 'probesysfs,provider=hidinput')

# General config path to load settings from (default path)
cfgpath = '/etc/guestwlan.cfg'

# Handle simple config param
if len(sys.argv) > 1:
    # TODO kivy overwrites the help page without -- before
    if sys.argv[1] == '--help' or len(sys.argv) > 2:
        print("Usage:", sys.argv[0], "[config_path]")
        print("Default path:", cfgpath)
        sys.exit(0)
    cfgpath = sys.argv[1]

# TODO check if config path exists
print(cfgpath)

# class SlideShow(Screen):
#     diashow = ObjectProperty(None)
#
#     #def on_touch_down(self, touch): relates only to own widget
#     def on_touch_down(self, touch):		# receives a touch event
#         # TODO global???
#         global sm 				# sm = screenmanager
#         # call function updatesettings and change screen to wlan
#         # Attention: in .kv the slide wlan has to have name: 'wlan'
#         sm.get_screen('wlan').updatesettings()
#         sm.transition.direction = 'left'
#         sm.current = 'wlan'
#
#     def next(self, dt):
#         Cache.remove('kivy.image')
#         Cache.remove('kivy.texture')
#         Cache.remove('image')
#         Cache.remove('texture')
#         self.diashow.load_next()

class SlideShow(Screen):
    slide = ObjectProperty(None)
    filename = []
    i = 0

    def addDirectory(self, name):
        # Add all pictures in directory
        types = ('*.jpg', '*.JPG', '*.png', '*.PNG', '*.jpeg', '*.JPEG')
        for files in types:
            self.filename.extend(glob(join(name, files)))

    def update(self):
        self.slide.source = self.filename[self.i]

    def next(self, dt):
        # Do not update the picutre if we are not in the slideshow
        # This prevents laggs and enhances the user expirience
        if sm.current != 'slideshow':
            return

        # Get next picture from the file index
        self.i += 1
        if self.i >= len(self.filename):
            self.i = 0
        return self.update()

class ScreenManagement(ScreenManager):
    pass

class GuestWLAN(BoxLayout):
    pass

class WLAN(Screen): # (Boxlayout) not anymore
    # definition of the variables
    # Attention: The QR-Codes are ObjectProperties
    wlanssid = StringProperty(None)
    wlanpsk = StringProperty(None)
    android_qrcode = ObjectProperty(None)
    ios_qrcode = ObjectProperty(None)
    windows_qrcode = ObjectProperty(None)

    def updatesettings(self):
        # TODO catch exception of permissions of the file
        guestwlan_cfg = configparser.RawConfigParser()
        guestwlan_cfg.read('/etc/guestwlan.cfg')

        # Workaround to open config file without section
        with open(guestwlan_cfg.get('WLAN', 'AP_CONFIG'), 'r') as f:
            create_guest_ap_cfg_string = '[ROOT]\n' + f.read()
        create_guest_ap_cfg = configparser.RawConfigParser()
        create_guest_ap_cfg.read_string(create_guest_ap_cfg_string)

        self.wlanssid = create_guest_ap_cfg.get('ROOT', 'SSID')
        self.wlanpsk = create_guest_ap_cfg.get('ROOT', 'PASSPHRASE')
        self.android_qrcode.reload()
        self.ios_qrcode.reload()
        self.windows_qrcode.reload()

class GuestWLANApp(App):
    def build(self):
        # Read config
        guestwlan_cfg = configparser.RawConfigParser()
        guestwlan_cfg.read(cfgpath)
        qrcode_path = guestwlan_cfg.get('GUI', 'QRCODE_PATH')
        photo_path = guestwlan_cfg.get('GUI', 'PHOTO_PATH')
        picture_speed = guestwlan_cfg.getint('GUI', 'PICTURE_SPEED')

        # Slidemanager
        global sm
        sm = self.root

        # Use QR code picture path from config
        wlan_screen = sm.get_screen('wlan')
        wlan_screen.android_qrcode.source = qrcode_path + '/AndroidWlan.png'
        wlan_screen.ios_qrcode.source = qrcode_path + '/iOSWlan.png'
        wlan_screen.windows_qrcode.source = qrcode_path + '/WindowsWlan.png'

        # Start diashow
        SlideShow = sm.get_screen('slideshow')
        SlideShow.addDirectory(photo_path)
        SlideShow.update()
        Clock.schedule_interval(SlideShow.next, picture_speed)

        # #TODO ignore folders
        # filename = []
        # filename.extend(glob(join('/home/alarm/pictures/', '*')))
        # for image_path in filename:
        #     image = Image(source = image_path, allow_stretch=True, nocache=True)
        #     #SlideShow.diashow.add_widget(image)
        #     print(image_path)
        #
        # # TODO load speed from config
        # Clock.schedule_interval(SlideShow.next, 3)

        return sm

if __name__ == "__main__":
    GuestWLANApp().run()
