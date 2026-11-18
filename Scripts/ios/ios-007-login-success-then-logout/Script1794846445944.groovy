import static com.kms.katalon.core.testobject.ObjectRepository.findTestObject

import ios.common.FlutterInput

import com.kms.katalon.core.mobile.keyword.MobileBuiltInKeywords as Mobile

import internal.GlobalVariable as GlobalVariable

Mobile.startApplication(GlobalVariable.APP_PATH.toString(), true)
Mobile.delay(8)

Mobile.tap(findTestObject('Object Repository/home/button_login'), 20)
FlutterInput.type(findTestObject('Object Repository/login/input_username'), 'standard_user')
FlutterInput.type(findTestObject('Object Repository/login/input_password'), 'secret_sauce')
Mobile.tap(findTestObject('Object Repository/login/button_sign_in'), 10)

Mobile.verifyElementVisible(findTestObject('Object Repository/home/txt_user_standard_user'), 30)
Mobile.tap(findTestObject('Object Repository/home/button_logout'), 20)
Mobile.verifyElementVisible(findTestObject('Object Repository/home/button_login'), 30)
Mobile.closeApplication()
