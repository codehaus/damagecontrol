package damagecontrol;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.1 $
 */
public class NoSuchBuilderException extends Exception {
    public NoSuchBuilderException(String builderName) {
        super("There is no builder registered with the name: " + builderName);
    }
}
