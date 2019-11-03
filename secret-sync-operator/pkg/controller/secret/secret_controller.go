package secret

import (
	"context"
	"fmt"
	"strings"
	"time"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller"
	// "sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/handler"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
	logf "sigs.k8s.io/controller-runtime/pkg/runtime/log"
	"sigs.k8s.io/controller-runtime/pkg/source"
)

var log = logf.Log.WithName("controller_secret")

// Add creates a new Secret Controller and adds it to the Manager. The Manager will set fields on the Controller
// and Start it when the Manager is Started.
func Add(mgr manager.Manager) error {
	return add(mgr, newReconciler(mgr))
}

// newReconciler returns a new reconcile.Reconciler
func newReconciler(mgr manager.Manager) reconcile.Reconciler {
	return &ReconcileSecret{client: mgr.GetClient(), scheme: mgr.GetScheme()}
}

// add adds a new Controller to mgr with r as the reconcile.Reconciler
func add(mgr manager.Manager, r reconcile.Reconciler) error {
	// Create a new controller
	c, err := controller.New("secretsync-controller", mgr, controller.Options{Reconciler: r})
	if err != nil {
		return err
	}

	// Watch for changes to primary resource Secret
	err = c.Watch(&source.Kind{Type: &corev1.Secret{}}, &handler.EnqueueRequestForObject{})
	if err != nil {
		return err
	}
	return nil
}

var _ reconcile.Reconciler = &ReconcileSecret{}

// ReconcileSecret reconciles a Secret object
type ReconcileSecret struct {
	// This client, initialized using mgr.Client() above, is a split client
	// that reads objects from the cache and writes to the apiserver
	client client.Client
	scheme *runtime.Scheme
}

func createSecret(secret *corev1.Secret, name string, namespace string) (*corev1.Secret, error){
	labels := map[string]string{
		"secretsync.ibm.com/replicated-from": fmt.Sprintf("%s.%s", secret.Namespace, secret.Name),
	}
	annotations := map[string]string{
		"secretsync.ibm.com/replicated-time": time.Now().Format("Mon Jan 2 15:04:05 MST 2006"),
		"secretsync.ibm.com/replicated-resource-version": secret.ResourceVersion,
	}
	return &corev1.Secret{
		TypeMeta: metav1.TypeMeta{
			APIVersion: secret.TypeMeta.APIVersion,
			Kind: secret.Kind,
		},
		ObjectMeta: metav1.ObjectMeta{
			Name: name,
			Namespace: namespace,
			Labels: labels,
			Annotations: annotations,
		},
		Data: secret.Data,
	}, nil
}

// Reconcile reads that state of the cluster for a Secret object and makes changes based on the state read
// and what is in the Secret.Spec
// Note:
// The Controller will requeue the Request to be processed again if the returned error is non-nil or
// Result.Requeue is true, otherwise upon completion it will remove the work from the queue.
func (r *ReconcileSecret) Reconcile(request reconcile.Request) (reconcile.Result, error) {
	reqLogger := log.WithValues("Request.Namespace", request.Namespace, "Request.Name", request.Name)
	reqLogger.Info("Reconciling Secret")

	// Fetch the Secret instance
	instance := &corev1.Secret{}
	err := r.client.Get(context.TODO(), request.NamespacedName, instance)
	if err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted after reconcile request.
			// Owned objects are automatically garbage collected. For additional cleanup logic use finalizers.
			// Return and don't requeue
			return reconcile.Result{}, nil
		}
		// Error reading the object - requeue the request.
		return reconcile.Result{}, err
	}

	namespaceMissing := false
	if rep, ok := instance.Annotations["secretsync.ibm.com/replicate"]; ok {
		if rep == "true" {
			if tgts, ok := instance.Annotations["secretsync.ibm.com/replicate-to"]; ok {
				namespaceType := &corev1.NamespaceList{}
				err := r.client.List(context.TODO(), &client.ListOptions{}, namespaceType)
				if err != nil {
					return reconcile.Result{}, err
				}
				namespaces := getNamespaces(namespaceType.Items)

				reqLogger.Info(fmt.Sprintf("Secret [%s] in the [%s] namespace is configured for sync to [%s].", instance.Name, instance.Namespace, tgts))
				targetList := strings.Split(tgts, ",")
				for _, target := range targetList {
					targetData := strings.Split(target, "/")
					targetSecret,err := createSecret(instance, targetData[1], targetData[0])
					if (err != nil){
						return reconcile.Result{}, err
					}
					if valueInList(targetSecret.Namespace, namespaces) {
						secret := &corev1.Secret{}

						err = r.client.Get(context.TODO(), types.NamespacedName{Name: targetSecret.Name, Namespace: targetSecret.Namespace}, secret)
						if err != nil && errors.IsNotFound(err) {
							reqLogger.Info(fmt.Sprintf("Target secret %s doesn't exist, creating it", target))
							err = r.client.Create(context.TODO(), targetSecret)
							if err != nil {
								return reconcile.Result{}, err
							}
						} else {
							reqLogger.Info(fmt.Sprintf("Target secret %s exists, updating it now", target))
							err = r.client.Update(context.TODO(), targetSecret)
							if err != nil {
								return reconcile.Result{}, err
							}
						}
					} else {
						reqLogger.Info(fmt.Sprintf("Namespace %s does not exist, not replicating and skipping namespace", targetSecret.Namespace))
						namespaceMissing = true
					}
				}
			}
		}
	}

	if namespaceMissing {
		//if a namespace is missing then retry to sync after 5 minutes in case it gets added at a later time
		return reconcile.Result{RequeueAfter: time.Minute * 5}, nil
	} else {
		return reconcile.Result{}, nil
	}
}

func getNamespaces(namespaceList []corev1.Namespace) []string {
	var namespaces []string
	for _, namespace := range namespaceList {
		namespaces = append(namespaces, namespace.Name)
	}
	return namespaces
}

func valueInList(value string, list []string) bool {
	for _, v := range list {
		if v == value {
			return true
		}
	}
	return false
}
