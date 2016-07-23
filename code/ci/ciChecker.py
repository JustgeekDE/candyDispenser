from lxml import etree
import argparse
import requests
import RPi.GPIO as GPIO
import time

class Servo:
  def __init__(self, pin):
    self.pin = pin
    self.frequency = 100

    GPIO.setmode(GPIO.BCM)
    GPIO.setup(self.pin, GPIO.OUT)
    self.pwm = GPIO.PWM(self.pin, self.frequency)
    self.pwm.start(15)
    self.move(90)

  def _getAngle(self, angle):
    pulseMin = 0.5
    pulseMax = 2.1
    cycleLength = 1000.0/self.frequency
    msPulse = (angle/180.0) *(pulseMax - pulseMin) + pulseMin
    dutyCycle = msPulse/cycleLength
    return dutyCycle*100

  def move(self, angle):
    self.pwm.ChangeDutyCycle(self._getAngle(angle))

  def slowMove(self, startAngle, targetAngle, duration, granularity = 360):
    for step in range(0,granularity+1):
      currentAngle = (step * ((float(targetAngle) - float(startAngle)) / granularity)) + startAngle
      self.move(currentAngle)
      time.sleep(float(duration) /granularity)

  def cleanup(self):
    GPIO.cleanup(self.pin)

class CCData:
  def __init__(self, currentXML):
    self.xml =  etree.fromstring(currentXML, etree.XMLParser(remove_blank_text=True))

  def getStatus(self, name):
    node = self._getNode(name)
    return node.get('lastBuildStatus')

  def getBuildLabel(self, name):
    node = self._getNode(name)
    return node.get('lastBuildLabel')

  def isBuilding(self, name):
    node = self._getNode(name)
    if node.get('activity') != "Sleeping":
      return True
    return False

  def _getNode(self, name):
    queryString = ".//Project[@name='{name}']".format(name=name)
    node = self.xml.find(queryString)
    return node

  def newBuildCompleted(self, name, newData):
    if newData.isBuilding(name):
      return False
    if self.getBuildLabel(name) != newData.getBuildLabel(name):
      return True

def getCurrentStatus(url):
  data = requests.get(url)

  if data.status_code == 200:
    return CCData(data.content)
  return False


url = "http://localhost:8081/cctray/pipeline.xml"
stageName = "gator :: integration-tests"
pwmPin = 18



def mainLoop(url, stageName, pwmPin, delay):
  servo = Servo(pwmPin)
  oldData = getCurrentStatus(url)
  while True:
    currentData = getCurrentStatus(url)

    if oldData.newBuildCompleted(stageName, currentData):
      print("Status changed: " + currentData.getStatus(stageName))
      if (currentData.getStatus(stageName) == 'Success'):
        servo.slowMove(0, 180, 1)
        time.sleep(1)
        servo.slowMove(180, 0, 1)
        time.sleep(1)

      oldData = currentData

    time.sleep(delay)

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Continously checks for changes on a ci server')
  parser.add_argument('-u', action="store", dest="url", help='Url of the cctray.xml')
  parser.add_argument('-n', action="store", dest="stageName", help='Name of the job/stage/project to monitor')
  parser.add_argument('-p', action="store", dest="pwmPin", help='GPIO pin that the servo is connected to', type=int, default=18)
  parser.add_argument('-d', action="store", dest="delay", help='update intervall in sleep seconds', type=int, default=60)

  args = parser.parse_args()
  mainLoop(args.url, args.stageName, args.pwmPin, args.delay)

