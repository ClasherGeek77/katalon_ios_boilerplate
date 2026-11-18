package ios.common

import com.kms.katalon.core.appium.driver.AppiumDriverManager
import com.kms.katalon.core.testobject.TestObject
import io.appium.java_client.ios.IOSDriver
import org.openqa.selenium.By
import org.openqa.selenium.Dimension
import org.openqa.selenium.Point
import org.openqa.selenium.WebElement
import org.openqa.selenium.support.ui.ExpectedConditions
import org.openqa.selenium.support.ui.WebDriverWait

/**
 * text into a flutter field the way ../pytest_boilerplate_ios proved:
 * xcuitest ACCEPTS send_keys on this app's flutter fields but the value
 * never lands (no UIAccessibilitySetValue behind them), so paste it —
 * `mobile: touchAndHold` opens the edit menu, the clipboard carries the
 * value, and the menu closing is the deterministic proof the paste took.
 */
public class FlutterInput {

	static final String PASTE_BUTTON = "//XCUIElementTypeButton[@name='Paste']"

	private static String xpathOf(TestObject to) {
		if (to instanceof com.kms.katalon.core.testobject.MobileTestObject) {
			String ml = to.getMobileLocator()
			if (ml != null && !ml.isEmpty()) {
				return ml
			}
		}
		String v = to.getSelectorCollection().get(to.getSelectorMethod())
		if (v == null || v.isEmpty()) {
			v = to.findPropertyValue("xpath")
		}
		return v
	}

	static void type(TestObject to, String value) {
		String xpath = xpathOf(to)
		IOSDriver<?> driver = (IOSDriver<?>) AppiumDriverManager.getDriver()
		WebElement field = new WebDriverWait(driver, 40).until(
			ExpectedConditions.presenceOfElementLocated(By.xpath(xpath)))
		// send_keys (WDA /value) is NOT attempted: with appium 1.22 / xcuitest
		// 3.59 against this flutter app the request hangs for minutes (the
		// pytest twin on driver 5.6.0 only silently dropped the value).
		// Paste works on any text field, so go straight to it.
		pasteInto(driver, field, value)
	}

	private static void pasteInto(IOSDriver<?> driver, WebElement field, String value) {
		Point p = field.getLocation()
		Dimension d = field.getSize()
		Map<String, Object> args = new HashMap<String, Object>()
		args.put("x", p.getX() + d.getWidth().intdiv(2))
		args.put("y", p.getY() + d.getHeight().intdiv(2))
		args.put("duration", 1.3d)
		driver.executeScript("mobile: touchAndHold", args)
		WebElement paste = new WebDriverWait(driver, 40).until(
			ExpectedConditions.presenceOfElementLocated(By.xpath(PASTE_BUTTON)))
		driver.setClipboardText(value)
		paste.click()
		new WebDriverWait(driver, 40).until(
			ExpectedConditions.invisibilityOfElementLocated(By.xpath(PASTE_BUTTON)))
	}
}
