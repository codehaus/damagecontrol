package com.thoughtworks.damagecontrolled;

import junit.framework.TestCase;

public class ThingyTestCase extends TestCase {
	public void testBeerIsGuinness() {
		assertEquals("Guinness", new Thingy().getBeer());
	}
}