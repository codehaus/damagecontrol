package damagecontrol;

/**
 * @author Aslak Helles&oslash;y
 * @version $Revision: 1.2 $
 */
public class NoSuchBuilderException extends RuntimeException {
    public NoSuchBuilderException(String builderName) {
        super("There is no builder registered with the name: " + builderName);
    }
}
