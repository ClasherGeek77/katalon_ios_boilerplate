import static com.kms.katalon.core.testobject.ObjectRepository.findTestObject

import ios.common.FlutterInput

import com.kms.katalon.core.mobile.keyword.MobileBuiltInKeywords as Mobile

import internal.GlobalVariable as GlobalVariable

Mobile.startApplication(GlobalVariable.APP_PATH.toString(), true)
Mobile.delay(8)

Mobile.verifyElementVisible(findTestObject('Object Repository/home/button_login'), 30)
Mobile.verifyElementVisible(findTestObject('Object Repository/home/txt_counter_label'), 15)
Mobile.closeApplication()
