package damagecontrol.modificationserver;

import damagecontrol.util.DamageControlException;

import java.util.StringTokenizer;
import java.lang.reflect.Method;
import java.lang.reflect.InvocationTargetException;

public abstract class ModificationEventFactory {

	public static ModificationEvent parseModificationEvent(String eventDescription) {
		StringTokenizer lineTok = new StringTokenizer(eventDescription, "\r\n");
		ModificationEvent result = null;
		while(lineTok.hasMoreTokens()) {
			String line = lineTok.nextToken();
			if(line.startsWith("SourceControlType: ")) {
				String sourceControlType = line.substring("SourceControlType: ".length());
				result = createNotificationClass(sourceControlType);
			} else if(line.indexOf(":") != -1) {
				int colonPos = line.indexOf(":");
				String fieldType = line.substring(0, colonPos);
				String fieldValue = line.substring(colonPos + 1);
				callSetter(result, fieldType.trim(), fieldValue.trim());
			} else {
				// Ignore the line, it's probably just a header
			}
		}
		return result;
	}

	private static ModificationEvent createNotificationClass(String sourceControlType) {
		Class modificationEventClass = null;
		String className = "damagecontrol.event." + sourceControlType + "ModificationEvent";
		try {
			modificationEventClass = Class.forName(className);
			return (ModificationEvent) modificationEventClass.newInstance();
		} catch (ClassNotFoundException e) {
			throw new DamageControlException("Couldn't find class " + className + " to create ModificationEvent");
		} catch (InstantiationException e) {
			throw new DamageControlException("Couldn't instantiate class " + className);
		} catch (IllegalAccessException e) {
			throw new DamageControlException("Couldn't access constructor for class " + className);
		}
	}

	private static void callSetter(ModificationEvent event, String fieldType, String fieldValue) {
		String methodName = "set" + capitalise(fieldType);
		Class[] argTypes = new Class[] { String.class };
		Object[] args = new Object[] { fieldValue };
		try {
			Method m = event.getClass().getMethod(methodName, argTypes);
			m.invoke(event, args);
		} catch (NoSuchMethodException e) {
			throw new DamageControlException("Couldn't find setter method " + methodName + " on ModificationEvent class");
		} catch (SecurityException e) {
			throw new DamageControlException("Couldn't call setter method " + methodName + " on ModificationEvent class");
		} catch (IllegalAccessException e) {
			throw new DamageControlException("Couldn't call setter method " + methodName + " on ModificationEvent class");
		} catch (IllegalArgumentException e) {
			throw new DamageControlException("Illegal argument calling setter method " + methodName + " on ModificationEvent class");
		} catch (InvocationTargetException e) {
			throw new DamageControlException("Invocation exception calling setter method " + methodName + " on ModificationEvent class");
		}
	}

	private static String capitalise(String s) {
		return Character.toUpperCase(s.charAt(0)) + s.substring(1);
	}
}
