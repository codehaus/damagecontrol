package com.thoughtworks.damagecontrolled;

import junit.framework.TestCase;

public class ThingyTestCase extends TestCase {
	public void testBeerIsGuinnes() {
		assertEquals("Guinnes", new Thingy().getBeer());
	}
}