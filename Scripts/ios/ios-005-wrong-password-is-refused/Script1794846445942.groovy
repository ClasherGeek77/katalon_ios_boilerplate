import static com.kms.katalon.core.testobject.ObjectRepository.findTestObject

import ios.common.FlutterInput

import com.kms.katalon.core.mobile.keyword.MobileBuiltInKeywords as Mobile

import internal.GlobalVariable as GlobalVariable

Mobile.startApplication(GlobalVariable.APP_PATH.toString(), true)
Mobile.delay(8)

Mobile.tap(findTestObject('Object Repository/home/button_login'), 20)
FlutterInput.type(findTestObject('Object Repository/login/input_username'), 'standard_user')
FlutterInput.type(findTestObject('Object Repository/login/input_password'), 'not_the_real_password')
Mobile.tap(findTestObject('Object Repository/login/button_sign_in'), 10)
Mobile.verifyElementVisible(findTestObject('Object Repository/login/txt_error_wrong_credentials'), 30)
Mobile.closeApplication()
